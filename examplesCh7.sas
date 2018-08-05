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

* Ejemplo 6;
%let A=0.0007;
%let B=0.00005;
%let c= 1.096478196143;
%let i=0.06;
%let p=1000;
%let x=110;
%seguroVitalicio(A=&A., B=&B., c=&c., i=&i., p=&p., x=&x.);
%let x6=40;
%let bft6=1000;
%let fxExp6=5;
%let pcExp6=0.1;

* Implementamos la solución en proc iml;
proc iml;
	edit trsf.iltplus;
	read all var _NUM_ into ILTplus[colname=numVars];
	close input.iltplus;
	* Prima de tarifa;
	G6=(&fxExp6.*ILTplus[&x6.+1, "aa_x"]+&bft6.*ILTplus[&x6.+1, 
		"A_x"])/((1-&pcExp6.)*ILTplus[&x6.+1, "aa_x"]);
	print G6;
	* Prima neta;
	P6=(&bft6.*ILTplus[&x6.+1, "A_x"])/(ILTplus[&x6.+1, "aa_x"]);
	print P6;
	* Prima de gastos;
	E6=G6-P6;
	print E6;
	namesRow={"Prima de Tarifa","Prima de Beneficios","Prima de Gastos"};
	namesCol={"Tipo de Prima" "Monto"};
	Pr=t(G6||P6||E6)||t(G6||P6||E6)/G6;
	print Pr;
	* Reservas;
	m=max(ILTplus[, "x"]-&x6.);
	t_V=j(m, 5, 0);

	do t=0 to m-1;
		t_V[t+1, 1]=&x6.+t;
		t_V[t+1, 2]=t;
		t_V[t+1, 3]=&bft6.*ILTplus[&x6.+1+t, "A_x"]-P6*ILTplus[&x6.+1+t, "aa_x"];
		t_V[t+1, 4]=&bft6.*ILTplus[&x6.+1+t, "A_x"]+&fxExp6.*ILTplus[&x6.+1+t, 
			"aa_x"]+&pcExp6.*G6*ILTplus[&x6.+1+t, "aa_x"]-G6*ILTplus[&x6.+1+t, "aa_x"];
		t_V[t+1, 5]=t_V[t+1, 4]-t_V[t+1, 3];
	end;
	* Guardamos la información en datasets;
	create rslt.t_V_Ex6 from t_V[colname={"x_t", "t", "t_V_P", "t_V_G", "t_V_E"}];
	append from t_V;
	close rslt.t_V_Ex6;
	create Pr_Ex6 from Pr[colname={"monto","porcentaje"}];
	append from Pr;
	close Pr_Ex6;	
run;

data Pr_Ex6_tipo;
	INFILE DATALINES DELIMITER=',';
	length tipo_prima $40;
	input tipo_prima $;
	label tipo_prima="Tipo de prima";
	datalines;
Prima de Tarifa
Prima de Beneficios
Prima de Gastos
;

data rslt.Pr_Ex6;
	set Pr_Ex6_tipo;
	set Pr_Ex6;
	format porcentaje percent6.2 monto dollar32.2;
run;


data rslt.t_V_Ex6;
	label  
		x_t="Edad" 
		t="Tiempo"
		t_V_P="Reserva de beneficios"
		t_V_G="Reserva total"
		t_V_E="Reserva de gastos";
	set rslt.t_V_Ex6;
	format t_V_P t_V_G t_V_E dollar32.2;
run;

%visualizar(reserves=rslt.t_V_Ex6,premiums=rslt.Pr_Ex6,age=&x6.,benefit=&bft6.);

* Ejercicio 7;
/*
%let A=0.0007;
%let B=0.00005;
%let c= 1.096478196143;
%let i=0.06;
%let p=1000;
%let x=110;
%seguroVitalicio(A=&A., B=&B., c=&c., i=&i., p=&p., x=&x.);
*/
%let x7=40;
%let bft7=.;
%let fxExp7=0;
%let fxInitExp7=20;
%let fxFinExp7=80;
%let pcExp7=0.1;
%let G7=30;

* Implementamos la solución en proc iml;
proc iml;
	edit trsf.iltplus;
	read all var _NUM_ into ILTplus[colname=numVars];
	close input.iltplus;
	* Beneficio;
	bft7=(&G7.*ILTplus[&x7.+1,"aa_x"]*(1-&pcExp7.)-&fxInitExp7.-&fxFinExp7.*ILTplus[&x7.+1,"A_x"])/ILTplus[&x7.+1,"A_x"];
	print bft7;
	call symputx('bft7',bft7);
	* Prima neta;
	P7=(bft7*ILTplus[&x6.+1, "A_x"])/(ILTplus[&x6.+1, "aa_x"]);
	print P7;
	* Prima de gastos;
	E7=&G7.-P7;
	print E7;
	namesRow={"Prima de Tarifa","Prima de Beneficios","Prima de Gastos"};
	namesCol={"Tipo de Prima" "Monto"};
	Pr=t(&G7.||P7||E7)||t(&G7.||P7||E7)/&G7.;
	print Pr;

	* Reservas;
	m=max(ILTplus[, "x"]-&x7.);
	t_V=j(m, 5, 0);

	do t=0 to m-1;
		t_V[t+1, 1]=&x7.+t;
		t_V[t+1, 2]=t;
		t_V[t+1, 3]=bft7*ILTplus[&x7.+1+t, "A_x"]-P7*ILTplus[&x7.+1+t, "aa_x"];
		t_V[t+1, 4]=(bft7+&fxFinExp7.)*ILTplus[&x6.+1+t, "A_x"]+&fxExp7.*ILTplus[&x7.+1+t, 
			"aa_x"]+&pcExp7.*&G7.*ILTplus[&x7.+1+t, "aa_x"]-&G7.*ILTplus[&x7.+1+t, "aa_x"];
		if t=0 then t_V[t+1, 4]=t_V[t+1, 4]+&fxInitExp7.;
		t_V[t+1, 5]=t_V[t+1, 4]-t_V[t+1, 3];
	end;
	* Guardamos la información en datasets;
	create rslt.t_V_Ex7 from t_V[colname={"x_t", "t", "t_V_P", "t_V_G", "t_V_E"}];
	append from t_V;
	close rslt.t_V_Ex7;
	create Pr_Ex7 from Pr[colname={"monto","porcentaje"}];
	append from Pr;
	close Pr_Ex7;	
run;


* Damos más propiedades a los metadatos;
data Pr_Ex7_tipo;
	INFILE DATALINES DELIMITER=',';
	length tipo_prima $40;
	input tipo_prima $;
	label tipo_prima="Tipo de prima";
	datalines;
Prima de Tarifa
Prima de Beneficios
Prima de Gastos
;

data rslt.Pr_Ex7;
	set Pr_Ex7_tipo;
	set Pr_Ex7;
	format porcentaje percent6.2 monto dollar32.2;
run;

data rslt.t_V_Ex7;
	label  
		x_t="Edad" 
		t="Tiempo"
		t_V_P="Reserva de beneficios"
		t_V_G="Reserva total"
		t_V_E="Reserva de gastos";
	set rslt.t_V_Ex7;
	format t_V_P t_V_G t_V_E dollar32.2;
run;

%visualizar(reserves=rslt.t_V_Ex7,premiums=rslt.Pr_Ex7,age=&x7.,benefit=&bft7.);

* Ejercicio 8 & 9;
%let x8=50;
%let n8=10;
%let bft8=1000;
%let unitBft8=1000;
%let fxExp8=5;
%let fxExpXunitBft8=10;
%let fxExpXunitG8=2;
%let fxInitExp8=20;
%let fxFinExp8=80;
%let pcInitExp8=0.5;
%let pcExp8=0.05;

proc iml;
	edit trsf.iltplus;
	read all var _NUM_ into ILTplus[colname=numVars];
	close input.iltplus;
	start termIns(x,n,i,tbl);
		A_x=tbl[x+1,7];
		A_xpn=tbl[x+1+n,7];
		l_x=tbl[x+1,2];
		l_xpn=tbl[x+1+n,2];	
		A_xn=A_x-(1/(1+i)**n)*l_xpn/l_x*A_xpn;
		return(A_xn);
	finish;
	
	start pureEnd(x,n,i,tbl);
		l_x=tbl[x+1,2];
		l_xpn=tbl[x+1+n,2];	
		n_E_x=(l_xpn/l_x)*(1/(1+i)**n);	
		return(n_E_x);
	finish;
	
	start end(x,n,i,tbl);
		A_xpn=termIns(x,n,i,tbl)+pureEnd(x,n,i,tbl);
		return(A_xpn);
	finish;
	
	start termAn(x,n,i,tbl);
		a_xn=(1-end(x,n,i,tbl))/(i/(1+i));
		return(a_xn);
	finish;

	* Prima de tarifa;
	%put &x8. &n8.;
	G8=(&fxInitExp8.+((1+&fxExpXunitBft8./&unitBft8.)*&bft8.+&fxFinExp8.)*end(&x8.,&n8.,&i.,ILTplus)+
	(&fxExp8.+&fxExpXunitG8./&unitBft8.*&bft8.)*termAn(&x8.,&n8.,&i.,ILTplus))
		/((1-&pcExp8.)*termAn(&x8.,&n8.,&i.,ILTplus)-(&pcInitExp8.-&pcExp8.));	
	print G8;
	* Prima neta;
	P8=&bft8.*end(&x8.,&n8.,&i.,ILTplus)/termAn(&x8.,&n8.,&i.,ILTplus);
	print P8;
	
	* Prima de gastos;
	E8=G8-P8;
	print E8;
	namesRow={"Prima de Tarifa","Prima de Beneficios","Prima de Gastos"};
	namesCol={"Tipo de Prima" "Monto"};
	Pr=t(G8||P8||E8)||t(G8||P8||E8)/G8;
	print Pr;
	* Reservas;
	m=&n8.+1;
	t_V=j(m, 5, 0);

	do t=0 to m-1;
		t_V[t+1, 1]=&x8.+t;
		t_V[t+1, 2]=t;
		t_V[t+1, 3]=&bft8.*end(&x8.+t,&n8.-t,&i.,ILTplus)-P8*termAn(&x8.+t,&n8.-t,&i.,ILTplus);
		t_V[t+1, 4]=((1+&fxExpXunitBft8./&unitBft8.)*&bft8.+&fxFinExp8.)*end(&x8.+t,&n8.-t,&i.,ILTplus)
		+(&fxExp8.+&fxExpXunitG8./&unitBft8.*&bft8.)*termAn(&x8.+t,&n8.-t,&i.,ILTplus)+&pcExp8.*G8*termAn(&x8.+t,&n8.-t,&i.,ILTplus)
		-G8*termAn(&x8.+t,&n8.-t,&i.,ILTplus);
		if t=0 then t_V[t+1, 4]=t_V[t+1, 4]+(&pcInitExp8.-&pcExp8.)*G8+&fxInitExp8.;
		t_V[t+1, 5]=t_V[t+1, 4]-t_V[t+1, 3];		
	end;
	* Guardamos la información en datasets;
	create rslt.t_V_Ex8 from t_V[colname={"x_t", "t", "t_V_P", "t_V_G", "t_V_E"}];
	append from t_V;
	close rslt.t_V_Ex8;
	create Pr_Ex8 from Pr[colname={"monto","porcentaje"}];
	append from Pr;
	close Pr_Ex8;	
	
run;

* Damos más propiedades a los metadatos;
data Pr_Ex8_tipo;
	INFILE DATALINES DELIMITER=',';
	length tipo_prima $40;
	input tipo_prima $;
	label tipo_prima="Tipo de prima";
	datalines;
Prima de Tarifa
Prima de Beneficios
Prima de Gastos
;

data rslt.Pr_Ex8;
	set Pr_Ex8_tipo;
	set Pr_Ex8;
	format porcentaje percent6.2 monto dollar32.2;
run;

data rslt.t_V_Ex8;
	label  
		x_t="Edad" 
		t="Tiempo"
		t_V_P="Reserva de beneficios"
		t_V_G="Reserva total"
		t_V_E="Reserva de gastos";
	set rslt.t_V_Ex8;
	format t_V_P t_V_G t_V_E dollar32.2;
run;

%visualizar(reserves=rslt.t_V_Ex8,premiums=rslt.Pr_Ex8,age=&x8.,benefit=&bft8.);



