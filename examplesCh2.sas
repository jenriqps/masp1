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

/*
data dummy;
 do subject = 1 to 100;
 do visit =1 to 6;
 random = rannor(1) + 0.5 + (visit+1)/30;
 riskfactors = min(3,floor(abs(random)));
 output;
 end;
 end;
run;

%sankeybarchart
 (data=dummy
 ,subject=subject
 ,yvar=riskfactors
 ,xvar=visit
 ,yvarord=%str(0,1,2,3)
 ,xvarord=%str(1,2,3,4,5,6)
 ,barwidth=0.45
 ,xfmt=xfmt.
 ,legendtitle=%str(# of Risk Factors)
 );
*/

%mortTable2Sankey(data=input.ilt,age=age,death=d_x,alive=l_x)
;
/*
proc freq data=trsf.ilt_sankey;
	table moment;
run;

proc sql;
	select *
	from trsf.ilt_sankey
	where subject=3000
	;
quit;
*/

/*
%sankeybarchart
 (data=trsf.ilt_sankey
 ,subject=subject
 ,yvar=status
 ,xvar=moment
 ,yvarord=%str(0,1)
 ,xvarord=%str(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)
 ,barwidth=0.45
 ,xfmt=xfmt.
 ,legendtitle=%str(# of Risk Factors)
 );
 */
 

 



