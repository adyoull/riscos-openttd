/* Bit-exactness test: 32bpp-sse4 (x86) vs 32bpp-neon (ARM, under qemu).
 * Same pseudo-random sprites, remaps and destination buffers on both; prints
 * FNV hashes of the encoded sprites and of the destination after each draw.
 * See run.sh. */
#include "stdafx.h"
#include "gfx_type.h"
#include "palette_func.h"
#include "settings_type.h"
#include "spriteloader/spriteloader.hpp"
#if defined(__ARM_NEON)
#include "blitter/32bpp_neon.hpp"
typedef Blitter_32bppNEON TestBlitter;
#else
#include "blitter/32bpp_sse4.hpp"
#include "blitter/32bpp_sse2.hpp"
#ifdef USE_SSE2
typedef Blitter_32bppSSE2 TestBlitter;
#else
typedef Blitter_32bppSSE4 TestBlitter;
#endif
#endif
#include <cstdio>
#include <cstdlib>
#include <vector>

Palette _cur_palette;
ClientSettings _settings_client;
ReusableBuffer<SpriteLoader::CommonPixel> SpriteLoader::Sprite::buffer[ZOOM_LVL_END];
uint8_t GetNearestColourIndex(uint8_t r, uint8_t g, uint8_t b) { return (uint8_t)((r * 7 + g * 13 + b * 29) & 0xFF); }

static uint32_t rs = 12345;
static uint32_t rnd() { rs ^= rs << 13; rs ^= rs >> 17; rs ^= rs << 5; return rs; }
static uint64_t fnv(const void *p, size_t n, uint64_t h = 1469598103934665603ULL) {
	const uint8_t *b = (const uint8_t *)p; for (size_t i = 0; i < n; i++) { h ^= b[i]; h *= 1099511628211ULL; } return h;
}
static void *alloc(size_t n) { return calloc(1, n); }

int main()
{
	for (int i = 0; i < 256; i++) { uint32_t v = rnd(); _cur_palette.palette[i] = Colour(v | 0xFF000000); }
	_cur_palette.palette[0] = Colour(0);
	_settings_client.gui.zoom_min = ZOOM_LVL_NORMAL;
	_settings_client.gui.zoom_max = ZOOM_LVL_OUT_2X;

	TestBlitter blitter;
	uint64_t enc_hash = 1469598103934665603ULL, draw_hash[8];
	for (auto &h : draw_hash) h = 1469598103934665603ULL;
	long draws = 0;

	const int DW = 160, DH = 120;
	std::vector<uint32_t> dst(DW * DH);

	for (int iter = 0; iter < 3000; iter++) {
		SpriteLoader::SpriteCollection sc;
		std::vector<std::vector<SpriteLoader::CommonPixel>> store(ZOOM_LVL_END);
		int w0 = 1 + rnd() % 70, h0 = 1 + rnd() % 40;
		for (ZoomLevel z = ZOOM_LVL_NORMAL; z <= ZOOM_LVL_OUT_2X; z++) {
			int w = std::max(1, w0 >> (z - ZOOM_LVL_NORMAL)), h = std::max(1, h0 >> (z - ZOOM_LVL_NORMAL));
			auto &sp = sc[z];
			sp.width = w; sp.height = h; sp.x_offs = 0; sp.y_offs = 0;
			sp.type = (iter % 17 == 0) ? SpriteType::Font : SpriteType::Normal;
			store[z].resize(w * h);
			int style = rnd() % 4; /* 0: opaque/transparent only, others mixed */
			for (auto &p : store[z]) {
				uint32_t r = rnd();
				p.r = r; p.g = r >> 8; p.b = r >> 16;
				if ((r >> 24) % 5 == 0) p.r = p.g = p.b = 0;
				uint32_t k = rnd() % 10;
				p.a = k < 3 ? 0 : (k < 7 || style == 0) ? 255 : (uint8_t)(1 + rnd() % 254);
				uint32_t mm = rnd() % 10;
				p.m = mm < 6 ? 0 : (uint8_t)(rnd() % 256);
			}
			sp.data = store[z].data();
		}
		if (sc[ZOOM_LVL_NORMAL].type == SpriteType::Font) {
			/* Fonts only encode the normal zoom. */
		}
		Sprite *s = blitter.Encode(sc, alloc);
		{
			/* Hash the contents per zoom level (the NEON encoder pads between levels). */
			const auto *sd = (const TestBlitter::SpriteData *)s->data;
			ZoomLevel zmax = sc[ZOOM_LVL_NORMAL].type == SpriteType::Font ? ZOOM_LVL_NORMAL : ZOOM_LVL_OUT_2X;
			enc_hash = fnv(&sd->flags, sizeof(sd->flags), enc_hash);
			enc_hash = fnv(s, 8, enc_hash);
			for (ZoomLevel z = ZOOM_LVL_NORMAL; z <= zmax; z++) {
				const auto &in = sd->infos[z];
				enc_hash = fnv(&sd->data[in.sprite_offset], (size_t)in.sprite_line_size * sc[z].height, enc_hash);
				enc_hash = fnv(&sd->data[in.mv_offset], (size_t)2 * in.sprite_width * sc[z].height, enc_hash);
			}
		}

		std::vector<uint8_t> remap(256);
		for (auto &r : remap) { uint32_t v = rnd(); r = (v % 7 == 0) ? 0 : (uint8_t)(v >> 8); }

		for (int mode = 0; mode < 6; mode++) {
			ZoomLevel z = (sc[ZOOM_LVL_NORMAL].type == SpriteType::Font) ? ZOOM_LVL_NORMAL : (ZoomLevel)(ZOOM_LVL_NORMAL + rnd() % 2);
			int sw = sc[z].width, sh = sc[z].height;
			for (auto &d : dst) d = rnd();
			Blitter::BlitterParams bp;
			bp.sprite = s->data;
			bp.remap = remap.data();
			bp.sprite_width = sw; bp.sprite_height = sh;
			bool clip = rnd() % 3 == 0;
			bp.skip_left = clip ? rnd() % sw : 0;
			bp.skip_top = clip ? rnd() % sh : 0;
			bp.width = sw - bp.skip_left - (clip ? rnd() % (sw - bp.skip_left) : 0);
			bp.height = sh - bp.skip_top - (clip ? rnd() % (sh - bp.skip_top) : 0);
			bp.left = rnd() % (DW - sw); bp.top = rnd() % (DH - sh);
			bp.dst = dst.data(); bp.pitch = DW;
			blitter.Draw(&bp, (BlitterMode)mode, z);
			draw_hash[mode] = fnv(dst.data(), dst.size() * 4, draw_hash[mode]);
			draws++;
		}
		free(s);
	}
	printf("encode %016llx\n", (unsigned long long)enc_hash);
	const char *names[] = { "normal", "colour_remap", "transparent", "transparent_remap", "crash_remap", "black_remap" };
	for (int m = 0; m < 6; m++) printf("%-18s %016llx\n", names[m], (unsigned long long)draw_hash[m]);
	printf("%ld draws\n", draws);
}
