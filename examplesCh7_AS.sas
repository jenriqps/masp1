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

	start p_sprv(x,s,ps,tm,n);
	/*
	Probabilidad de sobrevivencia
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
	Anualidad temporal
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
	Anualidad vitalicia
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
	Seguro temporal
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
	Seguro con incrementos aritméticos
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
	
	* Parámetros;
	x=50;
	n1=10;
	t1=5;
	t2=15;
	i=0.05;
	bft=10000;
	exp_bft1=25;
	exp_bft2=100;
	G=11900;
	
	
	* Cálculo de valores presentes actuariales necesarios para las reservas;
	a1=an_temporal(x,1,2,slt,n1,i);
	a2=an_temporal(x+t1,0,2,slt,n1-t1,i);
	a3=an_vitalicia(60,0,slt);
	a4=an_vitalicia(x+t2,0,slt);
	s1=seg_temporal(x,1,2,slt,n1,i);
	s2=seg_temporal(x+t1,0,2,slt,n1-t1,i);
	is1=incSeg_temporal(x,1,2,slt,n1,i);
	is2=incSeg_temporal(x+t1,0,2,slt,n1-t1,i);
	title "Reservas";
	V0=G*is1+exp_bft2*s1+(bft+exp_bft1)*(1+i)**(-10)*a3*p_sprv(x,1,2,slt,10)-(0.95*a1-0.05)*G;
	print V0;
	V5=G*(is2+5*s2)+exp_bft2*s2+(bft+exp_bft1)*(1+i)**(-5)*p_sprv(55,0,2,slt,5)*a3-0.95*G*a2;	
	print V5;
	V15=(bft+exp_bft1)*a4;
	print V15;
run;

title "Experiencia";
proc iml;
	* Asset shares;
	* Cargamos la experiencia;
	edit input.ASSETSHAREASSMPTS;
	read all var _NUM_ into exp[colname=numVars];
	close trsf.slt; 
	print exp;
	* Calculamos el asset share;
	N=666;
	G=11900;
	AS=J(5,11,0);
	do t=1 to 5 by 1;
		AS[t,1]=t;
		if t=1 then
		do;
			AS[t,2]=0;
			AS[t,9]=-G*exp[t,4]*N;
			AS[t,11]=G*N;
			AS[t,3]=AS[t,11]+AS[t,9];
			AS[t,5]=-(G*t+exp[t,5])*N*exp[t,3];
			AS[t,7]=N*(1-exp[t,3]);
		end;
		else 
		do;
			AS[t,2]=AS[t-1,6];
			AS[t,9]=-G*exp[t,4]*AS[t-1,7];
			AS[t,11]=G*AS[t-1,7];
			AS[t,3]=AS[t,11]+AS[t,9];
			AS[t,5]=-(G*t+exp[t,5])*AS[t-1,7]*exp[t,3];
			AS[t,7]=AS[t-1,7]*(1-exp[t,3]);
		end;
		AS[t,4]=(AS[t,2]+AS[t,3])*(1+exp[t,2]);
		AS[t,6]=AS[t,4]+AS[t,5];
		AS[t,8]=AS[t,6]/AS[t,7];
		AS[t,10]=(AS[t,2]+AS[t,3])*(exp[t,2]);
	end;
	* Enviamos los resultados a un data set;
	create work.assetshare from AS;
	append from AS;
	close work.assetshare;
run;

data rslt.assetshare;
	set work.assetshare;
	format col1 col7 comma32. 
	col2 col3 col4 col5 col6 col8 col9 col10 col11 dollar32.;	
	label
	col1="Año"
	col2="Fondo al inicio del año"
	col3="Movimiento de Dinero al inicio del año"
	col4="Fondo al final del año antes de los reclamo por muerte"
	col5="Reclamos por muerte y gastos asociados"
	col6="Fondo al final del año"
	col7="Sobrevivientes"
	col8="Asset Share"
	col9="Gastos de administración y adquisición"
	col10="Rendimientos"
	col11="Prima emitida"
	;
run;

title "Asset Share";
proc print data=rslt.assetshare noobs label;
run;

proc transpose data=rslt.assetshare(keep=col1 col2 col9 col10 col11 col5) out=work.assetshare2wf;
run;

data rslt.assetshare2wf(drop=col:);
	length type1 type2 type3 type4 type5 $15;
	format year1-year5 dollar32.;
	set work.assetshare2wf;
	year1=col1;
	if year1 < 0 then type1="Egreso"; else type1="Ingreso"; 
	year2=col2;
	if year2 < 0 then type2="Egreso"; else type2="Ingreso"; 
	year3=col3;
	if year3 < 0 then type3="Egreso"; else type3="Ingreso"; 
	year4=col4;
	if year4 < 0 then type4="Egreso"; else type4="Ingreso"; 
	year5=col5;
	if year5 < 0 then type5="Egreso"; else type5="Ingreso"; 
run;

title "Flujos de Efectivo durante al año 1";
proc sgplot data=rslt.assetshare2wf(where=(_label_ ne "Año"));
  waterfall category=_label_ response=year1  / colorgroup=type1 dataskin=sheen datalabel name='a';
  keylegend 'a' / location=outside position=topright;
  xaxis grid display=(nolabel);
  yaxis grid display=(nolabel);
run;

title "Flujos de Efectivo durante al año 2";
proc sgplot data=rslt.assetshare2wf(where=(_label_ ne "Año"));
  waterfall category=_label_ response=year2  / colorgroup=type2 dataskin=sheen datalabel name='a';
  keylegend 'a' / location=outside position=topright;
  xaxis grid display=(nolabel);
  yaxis grid display=(nolabel);
run;

title "Flujos de Efectivo durante al año 3";
proc sgplot data=rslt.assetshare2wf(where=(_label_ ne "Año"));
  waterfall category=_label_ response=year3  / colorgroup=type3 dataskin=sheen datalabel name='a';
  keylegend 'a' / location=outside position=topright;
  xaxis grid display=(nolabel);
  yaxis grid display=(nolabel);
run;

title "Flujos de Efectivo durante al año 4";
proc sgplot data=rslt.assetshare2wf(where=(_label_ ne "Año"));
  waterfall category=_label_ response=year4  / colorgroup=type4 dataskin=sheen datalabel name='a';
  keylegend 'a' / location=outside position=topright;
  xaxis grid display=(nolabel);
  yaxis grid display=(nolabel);
run;

title "Flujos de Efectivo durante al año 5";
proc sgplot data=rslt.assetshare2wf(where=(_label_ ne "Año"));
  waterfall category=_label_ response=year5  / colorgroup=type5 dataskin=sheen datalabel name='a';
  keylegend 'a' / location=outside position=topright;
  xaxis grid display=(nolabel);
  yaxis grid display=(nolabel);
run;









