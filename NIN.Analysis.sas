/** Read in data. NOTE: NAs changed to blanks  **/

PROC IMPORT OUT= WORK.wheat 
	DATAFILE= "C:\Users\bprice\Dropbox\Spatial\Stroup.NIN.wheat.csv" 
	DBMS=csv REPLACE;
RUN;


/** Plot Data  **/
proc sgplot;
	HEATMAPPARM y=col x=row COLORRESPONSE=yield/ colormodel=(blue yellow green); 
run;

proc sgplot;
	vbox yield/category=rep FILLATTRS=(color=red) LINEATTRS=(color=black) WHISKERATTRS=(color=black);
run;

proc sgplot;
	vbox yield/category=row FILLATTRS=(color=blue) LINEATTRS=(color=black) WHISKERATTRS=(color=black);
run;

proc sgplot;
	vbox yield/category=col FILLATTRS=(color=yellow) LINEATTRS=(color=black) WHISKERATTRS=(color=black);
run;

/** Extract residuals  **/
proc mixed data=wheat;
	class gen rep ;
	model yield = gen/ outp=res residual solution;
	random rep;
run;

/** Compute Moran's I **/
proc variogram data=res plots(only)=moran ;
   compute lagd=1 maxlag=24 autocorr(assum=random) ;
   coordinates xc=row yc=col;
   var resid;
run;

/** Extimate spherical model **/
proc variogram data=res ;
   compute lagd=.5 maxlag=24;
   coordinates xc=row yc=col;
   model form=sph;
   var resid;
run;

/** Fit unadjusted RCBD model **/
proc mixed data=wheat ;
	class gen rep;
	model yield = gen /ddfm=kr;
	random rep;
	lsmeans gen/cl;
	ods output LSMeans=NIN_RCBD_means;
	title1 'NIN data: RCBD';
run;

/** Fit spherical adjusted model **/
proc mixed data=wheat maxiter=150;
	class gen;
	model yield = gen /ddfm=kr;
	repeated/subject=intercept type=sp(sph) (row col) local;
	parms (11.31) (29.7) (16.8);
	lsmeans gen/cl;
	ods output LSMeans=NIN_Spatial_means;
	title1 'NIN data: Spherical Spatial';
run;

/** Gather means from two runs and plot them **/
data NIN_RCBD_means;
	set NIN_RCBD_means;
	Type='RCBD         ';
run;

data NIN_Spatial_means;
	set NIN_Spatial_means;
	Type='Spatial (sph)';
run;

data lsmeans;
	set NIN_Spatial_means NIN_RCBD_means;
run;

ODS GRAPHICS / RESET HEIGHT = 12in WIDTH = 15in antialias=on border=off;

proc sgplot data=lsmeans aspect=.5;
  	styleattrs datacolors=(green blue) datacontrastcolors=(black black);
	scatter y=estimate x=gen/group=type GROUPDISPLAY=cluster FILLEDOUTLINEDMARKERS markerattrs=(symbol=circlefilled size=14) MARKEROUTLINEATTRS=(color=black) ;
	highlow x=gen high=upper low=lower/group=type GROUPDISPLAY=cluster type=line highcap=serif lowcap=serif LINEATTRS=(thickness=1 color=black);
	xaxis label='Genotype' TYPE=discrete DISCRETEORDER=formatted LABELATTRS=( Family=Arial Size=15 Weight=Bold) VALUEATTRS=(Family=Arial Size=12 Weight=Bold);
	yaxis label="Estimated Mean" LABELATTRS=( Family=Arial Size=15 Weight=Bold) VALUEATTRS=(Family=Arial Size=10 Weight=Bold);
	title1 'Estimated Means';
run;	

proc sgplot data=lsmeans;
  	styleattrs datacolors=(white gray) datacontrastcolors=(black black);
	vbarparm category=gen response=estimate / LIMITATTRS=(color=black)
   	limitlower=lower limitupper=upper group=type OUTLINEATTRS=(color=black) groupdisplay=cluster;
	xaxis label='Genotype' TYPE=discrete DISCRETEORDER=formatted LABELATTRS=( Family=Arial Size=15 Weight=Bold) VALUEATTRS=(Family=Arial Size=12 Weight=Bold);
	yaxis label="Estimated Mean" LABELATTRS=( Family=Arial Size=15 Weight=Bold) VALUEATTRS=(Family=Arial Size=10 Weight=Bold);
run;
