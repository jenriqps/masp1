/**********************************************************************
 * Notas de Clase de Matematicas Actuariales del Seguro de Personas I ;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/
*options mprint mlogic minoperator fullstimer;
*ods graphics / reset width=6.4in height=4.8in imagemap noborder;

%let origen1=/folders/myfolders/masp1;
%let origen2=/folders/myfolders/sas-sankeybarchart/src;
%include "&origen1./configuration.sas";
%include "&origen1./extInputs.sas";
%include "&origen1./macros.sas";
%include "&origen2./rawtosankey.sas";
%include "&origen2./sankey.sas";
%include "&origen2./sankeybarchart.sas";


data dummy;
 do subject = 1 to 100;
 do visit =1 to 6;
 random = rannor(1) + 0.5 + (visit+1)/30;
 riskfactors = min(3,floor(abs(random)));
 output;
 end;
 end;
run;

proc export data=dummy
file="&origen1./simple_path.csv";
run;

%sankeybarchart
 (data=dummy
 ,subject=subject
 ,yvar=riskfactors
 ,xvar=visit
 ,yvarord=%str(0,1,2,3)
 ,xvarord=%str(1,2,3,4,5,6)
 ,barwidth=0.25
 ,xfmt=xfmt.
 ,legendtitle=%str(# of Risk Factors)
 );
*/
/*
%mortTable2Sankey(data=input.ilt,age=age,death=d_x,alive=l_x)
;



proc freq data=trsf.ilt_sankey;
	table moment;
run;

proc sql;
	select *
	from trsf.ilt_sankey
	where subject=3000
	;
quit;


proc format lib=trsf;
	value alive
		1 = "alive"
		0 = "death";
run;

proc datasets lib=trsf;
	modify ilt_sankey;
	format status alive.;	
run;
*/
/*
data test;
	do i=88 to 91;
	end;
run;

proc sql noprint;
	select i into: mom separated by ','
	from test
	;
	create table trsf.ilt_sankey_test as
	select *
	from trsf.ilt_sankey
	where moment between 88 and 91
	;
quit;

%put &mom.;
*/
/*
%sankeybarchart
 (data=trsf.ilt_sankey_test
 ,subject=subject
 ,yvar=status
 ,xvar=moment
 /*,yvarord=%str(0,alive)
 /*,xvarord=%str(&mom.)*/
 ,barwidth=0.05
 ,xfmt=xfmt.
 ,legendtitle=%str(Tabla de mortalidad)
 );
 */

 

 



