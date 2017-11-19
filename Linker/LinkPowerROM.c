#include <stdio.h>
#include <XCOFF.h>
#include <stdlib.h>

#ifdef macintosh
typedef unsigned long uint32_t;
typedef long int32_t;
typedef unsigned short uint16_t;
typedef short int16_t;
typedef unsigned char uint8_t;
typedef char int8_t;
#endif

uint32_t narrow[8];
uint32_t wide[2];

int slurp(char *path, uint8_t **datap, unsigned long *sizep)
{
	FILE *f;
	long pos;
	uint8_t *bytes;

	f = fopen(path, "rb");
	if(f == NULL) return 1;

	fseek(f, 0, SEEK_END);
	pos = ftell(f);
	fseek(f, 0, SEEK_SET);

	bytes = (uint8_t *)malloc(pos);
	if(bytes == NULL) return 1;

	fread(bytes, pos, 1, f);

	fclose(f);

	*datap = bytes;
	*sizep = pos;

	return 0; /* no error */
}

const uint16_t pretend_header[] = {
	0x01df /*f_magic*/,
	1 /*f_nscns*/,
	0xd611, 0x2977 /*f_timdat*/,
	0, 0 /*f_symptr*/,
	0, 2 /*f_nsyms*/,
	0 /*f_opthdr*/,
	0 /*f_flags*/,

	/* now for single .text symbol header */
	0x2e74, 0x6578, 0x7400, 0x0000 /*s_name = .text*/,
	0, 0 /*s_paddr*/,
	0, 0 /*s_vaddr*/,
	1234, 5678 /*s_size*/,
	0, 0x3c /*s_scnptr = len of this header*/,
	0, 0 /*s_relptr*/,
	0, 0 /*s_lnnoptr*/,
	0 /*s_nreloc*/,
	0 /*s_nlnno*/,
	0, 0x20 /*s_flags = text*/
};

const uint16_t pretend_footer[] = {
	0, 0,
	0, 0,
	0, 0,
	1, 0,
	0x6b01,
	1234, 5678,
	0, 0, 0,
	0x1100, 0, 0, 0
};


int main(int argc, char **argv)
{
	FILE *fp;
	uint8_t *buf, *sec, *dest;
	unsigned long buflen, seclen, destlen;
	unsigned long i;

	if(argc < 2)
	{
		fprintf(stderr, "%s: No command specified -- use tox, fromx or cksum\n", argv[0]);
		return 1;
	}
	
	if(!strcmp(argv[1], "cksum"))
	{
		unsigned long offset;

		if(argc < 3)
		{
			fprintf(stderr, "%s: %s: Specify a file!\n", argv[0], argv[1]);
			return 1;
		}

		if(argc < 4)
		{
			return 0;	/* No offset specified -- fail silently */
		}

		if(slurp(argv[2], &buf, &buflen))
		{
			fprintf(stderr, "%s: %s: Could not open input\n", argv[0], argv[1]);
			return 1;
		}

		offset = strtoul(argv[3], NULL, 0);

		if(offset > buflen - 40) {
			fprintf(stderr, "%s: Bad offset for ConfigInfo checksum: 0x%x\n", argv[0], offset);
			return 1;
		}

		memset(buf + offset, 0, 40);

		for(i=0; i<buflen; i++)
		{
			/* eight 4-byte sums, for each of eight byte lanes */
			narrow[i & 7] += buf[i];
		}

		for(i=0; i<buflen; i+=8)
		{
			/* a single 64-bit sum */
			uint32_t oldlow = wide[1];
			wide[0] += *(uint32_t *)(buf + i);
			wide[1] += *(uint32_t *)(buf + i + 4);
			if(wide[1] < oldlow) wide[0]++;
		}

		fp = fopen(argv[2], "r+b");
		if(!fp) {
			fprintf(stderr, "%s: Could not open output\n", argv[0]);
			return 1;
		}
		
		fseek(fp, offset, SEEK_SET);
		fwrite(narrow, sizeof narrow, 1, fp);
		fwrite(wide, sizeof wide, 1, fp);
		
		fclose(fp);
	}
	else
	{
		/* XCOFF personality */
		if(argc != 4) {
			fprintf(stderr, "Usage: %s (tox | fromx) IN OUT\n", argv[0]);
			return 1;
		}

		if(slurp(argv[2], &buf, &buflen))
		{
			fprintf(stderr, "%s: %s: Could not open input\n", argv[0], argv[1]);
			return 1;
		}

		if(!strcmp(argv[1], "tox"))
		{
			sec = buf;
			seclen = buflen;
		}
		else if(!strcmp(argv[1], "fromx"))
		{
			FileHdrPtr fhp;
			SectionHdrEntryPtr shp;

			fhp = (FileHdrPtr)buf;
			shp = (SectionHdrEntryPtr)(buf + sizeof *fhp + fhp->f_opthdr);

			sec = buf + shp->s_scnptr;
			seclen = shp->s_size;
		}

		/* now to create my template XCOFF */

		if(!strcmp(argv[1], "tox"))
		{
			destlen = sizeof pretend_header + seclen + sizeof pretend_footer;
			dest = (uint8_t *)malloc(destlen);
			if(dest == NULL)
			{
				fprintf(stderr, "%s: OOM\n", argv[0]);
				return 1;
			}

			memcpy(dest, (const char *)pretend_header, sizeof pretend_header);
			memcpy(dest + sizeof pretend_header, sec, seclen);
			memcpy(dest + sizeof pretend_header + seclen, (const char *)pretend_footer, sizeof pretend_footer);

			*(uint32_t *)(dest + 36) = seclen;
			*(uint32_t *)(dest + 8) = sizeof pretend_header + seclen;
			*(uint32_t *)(dest + sizeof pretend_header + seclen + 18) = seclen;
		}
		else if(!strcmp(argv[1], "fromx"))
		{
			dest = sec;
			destlen = seclen;
		}

		fp = fopen(argv[3], "wb");
		if(!fp) {
			fprintf(stderr, "%s: Could not open output\n", argv[0]);
			return 1;
		}
		
		fwrite(dest, 1, destlen, fp);
		
		fclose(fp);
	}
	
	return 0;
}
