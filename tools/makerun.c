/* Minimal stand-in for NetSurf's makerun, for hosts that cannot fetch it.
   makerun <runimage> <template> <output>: writes template with a WimpSlot
   line sized from the executable (ELF PT_LOAD memsz or file size) + 64K. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
int main(int argc,char**argv){
 if(argc!=4){fprintf(stderr,"usage: makerun runimage template output\n");return 1;}
 FILE*f=fopen(argv[1],"rb"); if(!f){perror(argv[1]);return 1;}
 fseek(f,0,SEEK_END); long sz=ftell(f); rewind(f);
 unsigned char h[52]; unsigned long need=sz;
 if(fread(h,1,52,f)==52 && !memcmp(h,"\177ELF",4)){
   uint32_t phoff=h[28]|h[29]<<8|h[30]<<16|(uint32_t)h[31]<<24; int phent=h[42]|h[43]<<8, phnum=h[44]|h[45]<<8;
   unsigned long lo=~0UL,hi=0;
   for(int i=0;i<phnum;i++){unsigned char p[32]; fseek(f,phoff+i*phent,SEEK_SET); if(fread(p,1,32,f)!=32)break;
     uint32_t type=p[0]|p[1]<<8|p[2]<<16|(uint32_t)p[3]<<24; if(type!=1)continue;
     uint32_t va=p[8]|p[9]<<8|p[10]<<16|(uint32_t)p[11]<<24, ms=p[20]|p[21]<<8|p[22]<<16|(uint32_t)p[23]<<24;
     if(va<lo)lo=va; if(va+ms>hi)hi=va+ms;}
   if(hi>lo) need=hi-lo;
 }
 fclose(f);
 unsigned long k=(need+65536+1023)/1024;
 FILE*t=fopen(argv[2],"r"),*o=fopen(argv[3],"w"); if(!t||!o){perror("open");return 1;}
 char line[4096]; int done=0;
 while(fgets(line,sizeof line,t)){
   if(!done && !strncasecmp(line,"WimpSlot",8)){fprintf(o,"WimpSlot -min %luK -max %luK\n",k,k);done=1;continue;}
   if(!done && line[0]!='|'){fprintf(o,"WimpSlot -min %luK -max %luK\n",k,k);done=1;}
   fputs(line,o);
 }
 if(!done)fprintf(o,"WimpSlot -min %luK -max %luK\n",k,k);
 fclose(t);fclose(o);return 0;}
