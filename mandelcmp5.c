#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <gmp.h>

// Code is GPLed, original script by Marko Riedel,
// markoriedelde@gmail.com

#define MAXCMP 256
#define MAXUPP (MAXCMP-1)

#define TOTALCOLS 40
#define MAXITER (10*TOTALCOLS+1)

int main(int argc, char **argv)
{
  int hres = 200, vres = 200;
  mpf_t rmin, rmax, imin, imax;

  mpf_init_set_d(rmin, -1.5);
  mpf_init_set_d(rmax, 0.5);
  mpf_init_set_d(imin, -1);
  mpf_init_set_d(imax, 1);  

  argc--;
  
  if(argc >= 1) hres = atoi(argv[1]);
  assert(hres >= 32);

  if(argc >= 2) vres = atoi(argv[2]);
  assert(vres >= 32);

  if(argc >= 3) mpf_set_str(rmin, argv[3], 10);
  if(argc >= 4) mpf_set_str(rmax, argv[4], 10);
  assert(mpf_cmp(rmin, rmax) == -1);

  if(argc >= 5) mpf_set_str(imin, argv[5], 10);
  if(argc >= 6) mpf_set_str(imax, argv[6], 10);
  assert(mpf_cmp(imin, imax) == -1);


  int precision = 64;

  if(argc >=7 ) precision = atoi(argv[7]);
  assert(64 <= precision && precision <= 4096);

  mpf_set_default_prec(precision);
  
  printf("P3\n%d %d\n%d\n", hres, vres, MAXUPP);

  mpf_t rdelta; mpf_init_set(rdelta, rmax);
  mpf_sub(rdelta, rdelta, rmin);
  mpf_div_ui(rdelta, rdelta, hres);

  mpf_t idelta; mpf_init_set(idelta, imax);
  mpf_sub(idelta, idelta, imin);
  mpf_div_ui(idelta, idelta, vres);
  
  mpf_t upper; mpf_init_set_d(upper, 4.0);
  
  for(int ipos=0; ipos < vres; ipos++){
    mpf_t icur;
    mpf_init_set_ui(icur, ipos);
    mpf_mul(icur, icur, idelta);
    mpf_sub(icur, imax, icur);
    
    for(int rpos=0; rpos < hres; rpos++){
      mpf_t rcur;
      mpf_init_set_ui(rcur, rpos);
      mpf_mul(rcur, rcur, rdelta);
      mpf_add(rcur, rmin, rcur);
      
      int count = 0;

      mpf_t rsq, isq, mx, rz, iz;

      mpf_init_set_ui(rsq, 0);
      mpf_init_set_ui(isq, 0);

      mpf_init_set_ui(rz, 0);
      mpf_init_set_ui(iz, 0);

      mpf_init_set_ui(mx, 0);
      
      while(count<MAXITER){
	mpf_t mag; mpf_init(mag);
	mpf_add(mag, rsq, isq);
	int cmp = mpf_cmp(mag, upper);
	mpf_clear(mag);

	if(cmp != -1) break;

	// rsq = rz*rz; isq = iz*iz; mx = 2*rz*iz;

	mpf_mul(rsq, rz, rz);
	mpf_mul(isq, iz, iz);
	
	mpf_mul(mx, rz, iz);
	mpf_add(mx, mx, mx);

	// rz = rsq - isq + rcur;

	mpf_sub(rz, rsq, isq);
	mpf_add(rz, rz, rcur);
	
	// iz = mx + icur;

	mpf_add(iz, mx, icur);
                
	count++;
      }

      int cmp[3] = { 0, 0, 0};

      if(count < MAXITER){
	int idx = count % TOTALCOLS;
	struct { int cmpf[3], cmpt[3];
	} colrange[4] = {
	  { { 255, 255, 0}, { 255, 0, 0} },
	  { { 255, 15, 15}, { 255, 127, 0 } },
	  { { 255, 143, 0}, { 0, 0, 255 } },
	  { { 15, 15, 255}, { 239, 239, 0} }
	};

	int range = idx / (TOTALCOLS/4);

	int rgb;
	for(rgb=0; rgb<3; rgb++){
	  int ext = idx % (TOTALCOLS/4);
	  
	  cmp[rgb] = colrange[range].cmpf[rgb]
	    + ext*(colrange[range].cmpt[rgb]
		   -colrange[range].cmpf[rgb])
	    / (TOTALCOLS/4-1);
	}
      }

      printf("%d %d %d", cmp[0], cmp[1], cmp[2]);
      
      if(rpos == hres-1)
	putchar('\n');
      else
	putchar(' ');

      mpf_clear(rsq);
      mpf_clear(isq);

      mpf_clear(rz);
      mpf_clear(iz);

      mpf_clear(mx);

      mpf_clear(rcur);
    }
    mpf_clear(icur);
  }

  mpf_clear(upper);

  mpf_clear(rmin); mpf_clear(rmax);
  mpf_clear(imin); mpf_clear(imax);

  mpf_clear(rdelta); mpf_clear(idelta);
  
  return  0;
}
