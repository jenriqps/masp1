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
	
	*print slt;

	start p_sprv(x,s,ps,tm,n);
	/*
	x: edad
	s: indica si la edad es seleccionada (s=1) o agregada (s=0)
	ps: periodo de selección (solo aplica si s=1)
	tm: nombre del dataset de la tabla de mortalidad
	n: temporalidad (en años)
	*/
		if s=1 & n>=ps then
		p=tm[x+n-20+1,5]/tm[x-18+1,3];
		if s=1 & n<ps then
		p=tm[x+n-19+1,4]/tm[x-18+1,3];
		if s=0 then
		p=tm[x+n-20+1,5]/tm[x-20+1,5];
		
		return(p);
	finish;

	
	start an_temporal(x,s,ps,tm,n,i);
	/*
	x: edad
	s: indica si la edad es seleccionada (s=1) o agregada (s=0)
	ps: periodo de selección (solo aplica si s=1)
	tm: nombre del dataset de la tabla de mortalidad
	n: temporalidad (en años)
	i: tasa de interés
	*/
		if s=1 & n>=ps then
		an=tm[x-18+1,7] - tm[x+n-20+1,9]*(1+i)**(-n)*p_sprv(x,s,ps,tm,n);
		if s=1 & n<ps then
		an=tm[x-18+1,7] - tm[x+n-19+1,8]*(1+i)**(-n)*p_sprv(x,s,ps,tm,n);
		if s=0 then
		an=tm[x-20+1,9] - tm[x+n-20+1,9]*(1+i)**(-n)*p_sprv(x,s,ps,tm,n);
		
		return(an);
	finish;

	start an_vitalicia(x,s,tm);
	/*
	x: edad
	s: indica si la edad es seleccionada (s=1) o agregada (s=0)
	tm: nombre del dataset de la tabla de mortalidad
	*/
		if s=1 then
		an=tm[x-18+1,7];
		if s=0 then
		an=tm[x-20+1,9];		
		return(an);
	finish;
	
	start seg_temporal(x,s,ps,tm,n,i);
	/*
	x: edad
	s: indica si la edad es seleccionada (s=1) o agregada (s=0)
	ps: periodo de selección (solo aplica si s=1)
	tm: nombre del dataset de la tabla de mortalidad
	n: temporalidad (en años)
	i: tasa de interés
	*/
	d=i/(1+i);
		if s=1 & n>=ps then
			do;
			s1=1-d*tm[x-18+1,7];
			s2=1-d*tm[x+n-20+1,9];
			seg=s1 - s2*(1+i)**(-n)*p_sprv(x,s,ps,tm,n);
			end;
		if s=1 & n<ps then
			do;
			s1=1-d*tm[x-18+1,7];
			s2=1-d*tm[x+n-19+1,8];
			seg=s1 - s2*(1+i)**(-n)*p_sprv(x,s,ps,tm,n);
			end;
		if s=0 then
			do;
			s1=1-d*tm[x-20+1,9];
			s2=1-d*tm[x+n-20+1,9];
			seg=s1 - s2*(1+i)**(-n)*p_sprv(x,s,ps,tm,n);
			end;		
		return(seg);
	finish;
	
	start incSeg_temporal(x,s,ps,tm,n,i);
	/*
	x: edad
	s: indica si la edad es seleccionada (s=1) o agregada (s=0)
	ps: periodo de selección (solo aplica si s=1)
	tm: nombre del dataset de la tabla de mortalidad
	n: temporalidad (en años)
	i: tasa de interés
	*/
	aux=0;
				do k=1 to n-1 by 1;
				aux=aux+Seg_temporal(x,s,ps,tm,k,i);			
				end;
				incSeg=n*Seg_temporal(x,s,ps,tm,n,i)-aux;
		return(incSeg);
	finish;

	
	a1=an_temporal(50,1,2,slt,10,0.05);
	print a1;
	a2=an_temporal(55,0,2,slt,5,0.05);
	print a2;
	a3=an_vitalicia(60,0,slt);
	print a3;
	a4=an_vitalicia(65,0,slt);
	print a4;
	s1=seg_temporal(50,1,2,slt,10,0.05);
	print s1;
	s2=seg_temporal(55,0,2,slt,5,0.05);
	print s2;
	is1=incSeg_temporal(50,1,2,slt,10,0.05);
	print is1;
	is2=incSeg_temporal(55,0,2,slt,5,0.05);
	print is2;
	* Reserva al tiempo cero;
	G=11900;
	V0=G*is1+100*s1+10025*(1.05)**(-10)*a3*p_sprv(50,1,2,slt,10)-(0.95*a1-0.05)*G;
	print V0;
	* Reserva al tiempo cinco años;
	V5=G*(is2+5*s2)+100*s2+10025*1.05**(-5)*p_sprv(55,0,2,slt,5)*a3-0.95*G*a2;	
	print V5;
	* Reserva al tiempo 15 años;
	V15=10025*a4;
	print V15;
run;

proc iml;
	* Asset shares;
	edit input.ASSETSHAREASSMPTS;
	read all var _NUM_ into exp[colname=numVars];
	close trsf.slt; 
	print exp;
	N=666;
	G=11900;
	AS=J(5,8,0);
	do t=1 to 5 by 1;
		AS[t,1]=t;
		if t=1 then
		do;
			AS[t,2]=0;
			AS[t,3]=G*(1-exp[t,4])*N;
			AS[t,5]=(G*t+exp[t,5])*N*exp[t,3];
			AS[t,7]=N*(1-exp[t,3]);
		end;
		else 
		do;
			AS[t,2]=AS[t-1,6];
			AS[t,3]=G*(1-exp[t,4])*AS[t-1,7];
			AS[t,5]=(G*t+exp[t,5])*AS[t-1,7]*exp[t,3];
			AS[t,7]=AS[t-1,7]*(1-exp[t,3]);
		end;
		AS[t,4]=(AS[t,2]+AS[t,3])*(1+exp[t,2]);
		AS[t,6]=AS[t,4]-AS[t,5];
		AS[t,8]=AS[t,6]/AS[t,7];
	end;
	print AS;	
	* Enviamos los resultados a un data set;
	create work.assetshare from AS;
	append from AS;
	close work.assetshare;
run;

data rslt.assetshare;
	set work.assetshare;
	format col1 col7 comma32. 
	col2 col3 col4 col5 col6 col8 dollar32.2;	
	label
	col1="Año"
	col2="Fondo al inicio del año"
	col3="Movimiento de Dinero al inicio del año"
	col4="Fondo al final del año antes de los reclamo por muerte"
	col5="Reclamos por muerte y gastos"
	col6="Fondo al final del año"
	col7="Sobrevivientes"
	col8="Asset Share"
	;	
run;

title "Asset Share";
proc print data=rslt.assetshare noobs label;
run;









