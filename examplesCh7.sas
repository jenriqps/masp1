/**********************************************************************
 * Notas de Clase de Matematicas Actuariales del Seguro de Personas I ;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/
options mprint mlogic minoperator fullstimer;
ods graphics / reset width=6.4in height=4.8in imagemap noborder;

%let origen=/folders/myfolders/masp1;
%include "&origen./configuration.sas";
%include "&origen./extInputs.sas";
%include "&origen./macros.sas";

proc datasets lib=work kill nolist;
run;

/*
%examplesChapter7(example=&example_.,i=&i_.,x=&x_.,bft=&bft_.,fxExp=&fxExp_.,pcExp=&pcExp_.,fxInitExp=&fxInitExp.,fxFinExp=&fxFinExp.,G=&G.,n=&n.,unitBft=&unitBft.,fxExpXunitBft=&fxExpXunitBft.,fxExpXunitG=&fxExpXunitG.,pcInitExp=&pcInitExp.)
;
*/

* Parámetros de la tabla Dickson;
%let Ap=0.00022;
%let Bp=0.0000027;
%let cp=1.124;
%let c2p=0.9;
%let l_radixp=100000;
%let x_radixp=20;
%let x_endp=131;
%let ip=0.05;

%tablaDickson(A=&Ap.,B=&Bp.,c=&cp.,c2=&c2p.,l_radix=&l_radixp.,x_radix=&x_radixp.,x_end=&x_endp.,i=&ip.);

* Ejemplo 10;

proc iml;
	edit trsf.slt;
	read all var _NUM_ into slt[colname=numVars];
	close trsf.slt; 
	
	print slt;
	
	start an_temporal(x,s,ps,tm,n,i);
		if s=1 & n>=ps then
		an=tm[x-18+1,7] - tm[x+n-20+1,9]*(1+i)**(-n)*tm[x+n-20+1,5]/tm[x-18+1,3];
		if s=1 & n<ps then
		an=tm[x-18+1,7] - tm[x+n-19+1,8]*(1+i)**(-n)*tm[x+n-19+1,4]/tm[x-18+1,3];
		if s=0 then
		an=tm[x-20+1,9] - tm[x+n-20+1,9]*(1+i)**(-n)*tm[x+n-20+1,5]/tm[x-20+1,5];
		
		return(an);
	finish;
	
	a1=an_temporal(50,1,2,slt,10,0.05);
	print a1;
	a2=an_temporal(55,0,2,slt,5,0.05);
	print a2;
	
run;









