/**********************************************************************
 * Notas de Clase de Matematicas Actuariales del Seguro de Personas I ;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/
/********************
 * Macros
 *******************/

%macro seguroVitalicio(A=, B=, c=, i=, p=, x=);
	proc iml;
		* VPA de una anualidad con ley de Makeham;
		start segVit(A, B, c, i, p, x);
			m=B/log(c);
			an=0;
			do k=0 to p;
				an=an + (1 + i) ** -k * Exp(-A * k - m * (c ** (x + k) - c ** x));
			end;
			SegVit=1 - (i / (1 + i)) * an;
			return(SegVit);
		finish;
		* Abrimos el data set de la tabla de mortalidad; 
		edit input.ilt;
		read all var _NUM_ into ILT[colname=numVars];
		close input.ilt;
		* Calculamos la probabilidad de muerte y supervivencia;
		q_x=ILT[, 'd_x']/ILT[, 'l_x'];
		p_x=1-q_x;
		n_ILT=nrow(ILT);
		* Calculamos la esperanza;		
		e_x=j(n_ILT, 1, 0);
		do i=n_ILT to 1 by -1;
			if i=n_ILT then
				e_x[i, 1]=p_x[i, ];
			else
				e_x[i, 1]=p_x[i, ]*(1+e_x[i+1, ]);
		end;
		* Calculamos el VPA del seguro vitalicio;
		A_x=j(n_ILT, 1, 0);
		do i=n_ILT to 1 by -1;

			if i=n_ILT then
				A_x[i, 1]=segVit(&A., &B., &c., &i., &p., ILT[n_ILT, 1]);
			else
				A_x[i, 1]=q_x[i, 1]*1/(1+&i.)+p_x[i, 1]*A_x[i+1, 1]/(1+&i.);
		end;
		* Calculamos el VPA de la anualidad vitalicia;
		aa_x=j(n_ILT, 1, 0);
		aa_x=(1-A_x)/(&i./(1+&i.));
		* Unimos la información en una matriz;
		ILTplus=ILT||q_x||p_x||e_x||A_x||aa_x;
		create trsf.ILTplus from ILTplus[colname={"x", "l_x", "d_x", "q_x", "p_x", 
			"e_x", "A_x", "aa_x"}];
		append from ILTplus;
		close trsf.ILTplus;
	run;
	
	proc datasets lib=work kill nolist;
	run;

%mend;

%macro visualizar(reserves=,premiums=,age=,benefit=);
	title "Comparación de Reservas";
	proc sgplot data=&reserves.;
		series x=x_t y=t_V_P / markers lineattrs=(pattern=10 thickness=4) markerattrs=(size=1);
		series x=x_t y=t_V_G / markers lineattrs=(pattern=10 thickness=4) markerattrs=(size=1);
		series x=x_t y=t_V_E / y2axis markers lineattrs=(pattern=10 thickness=4) markerattrs=(size=1);
		yaxis grid label="Reserva" /*max=&benefit.*/;
		xaxis label="Edad" grid;	
		refline &age. / label='Edad original' axis=x lineattrs=(color=red thickness=3 pattern=dash);
		refline &benefit. / label='Beneficio' axis=y lineattrs=(color=red thickness=3 pattern=dash);
	run;
	title;
	
	title "Comparación de Primas (monto)";
	proc sgplot data=&premiums.;
		vbar tipo_prima / response=monto group=monto groupdisplay=stack;
		yaxis grid;
	run;
	title;
	
	title "Comparación de Primas (%)";
	proc sgplot data=&premiums.;
		vbar tipo_prima / response=porcentaje group=porcentaje groupdisplay=stack;
		yaxis grid;
	run;
	title;
%mend;

%macro mortTable2Sankey(data=,age=,death=,alive=);

	proc datasets lib=trsf;
		delete ilt_sankey;
	run;

	proc sql;
		select min(&age.) into: minAge
		from &data.
		;
		select max(&age.) into: maxAge
		from &data.
		;	
		select &alive. format 32. into: aliveInit
		from &data.
		where &age. = &minAge.
		;
	quit;
	
	%put &aliveInit.;
	
	data sankey;
		do subject = 1 to &aliveInit.;
			moment=&minAge.;
			status=1;
			output;
		end;
	run;
	
	data _null_;
		set &data.;
		var="var_"||compress(put(&age.,3.));
		call symputx(var,max(floor(&death.),1));
	run;

	%do x=&minAge. %to &maxAge.;
	
		%put &&&&var_&&x.;
		proc surveyselect data=sankey(where=(status=1 and moment=&x.)) sampsize=&&&&var_&&x. out=sankey_smpl seed=321 outall;
		run;
		
		data sankey_smpl(drop=selected);
			set sankey_smpl;
			moment = &x.+1;
			if selected = 1 then status = 0;
		run;	
		
		data sankey_death;
			set sankey(where=(status=0 and moment=&x.));
			moment = &x.+1;
		run;
		
		data sankey;
			set sankey sankey_smpl sankey_death;
		run;
		
		proc freq data=sankey(where=(moment=&x.));
			table status;
		run;		
	%end;
	
	data trsf.ilt_sankey;
		set work.sankey;
	run;
	
	proc datasets lib=work kill;
	run;
	
%mend;

%macro examplesChapter7(example=,i=,x=,bft=,fxExp=,pcExp=);

%let A=0.0007;
%let B=0.00005;
%let c= 1.096478196143;
%let i=0.06;
%let p=1000;
%let xmax=110;
%seguroVitalicio(A=&A., B=&B., c=&c., i=&i., p=&p., x=&xmax.);
/*
%let x6=40;
%let bft6=1000;
%let fxExp6=5;
%let pcExp6=0.1;
*/



* Implementamos la solución en proc iml;

%if "&example."="Ejemplo 6" %then;
	%do;
		* Ejemplo 6;
		proc iml;
			edit trsf.iltplus;
			read all var _NUM_ into ILTplus[colname=numVars];
			close input.iltplus;
			* Prima de tarifa;
			G6=(&fxExp.*ILTplus[&x.+1, "aa_x"]+&bft.*ILTplus[&x.+1, 
				"A_x"])/((1-&pcExp.)*ILTplus[&x.+1, "aa_x"]);
			print G6;
			* Prima neta;
			P6=(&bft.*ILTplus[&x.+1, "A_x"])/(ILTplus[&x.+1, "aa_x"]);
			print P6;
			* Prima de gastos;
			E6=G6-P6;
			print E6;
			namesRow={"Prima de Tarifa","Prima de Beneficios","Prima de Gastos"};
			namesCol={"Tipo de Prima" "Monto"};
			Pr=t(G6||P6||E6)||t(G6||P6||E6)/G6;
			print Pr;
			* Reservas;
			m=max(ILTplus[, "x"]-&x.);
			t_V=j(m, 5, 0);
		
			do t=0 to m-1;
				t_V[t+1, 1]=&x.+t;
				t_V[t+1, 2]=t;
				t_V[t+1, 3]=&bft.*ILTplus[&x.+1+t, "A_x"]-P6*ILTplus[&x.+1+t, "aa_x"];
				t_V[t+1, 4]=&bft.*ILTplus[&x.+1+t, "A_x"]+&fxExp.*ILTplus[&x.+1+t, 
					"aa_x"]+&pcExp.*G6*ILTplus[&x.+1+t, "aa_x"]-G6*ILTplus[&x.+1+t, "aa_x"];
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
/*		
data Pr_Ex6_tipo;
INFILE DATALINES DELIMITER=',';
length tipo_prima $40;
input tipo_prima $;
label tipo_prima="Tipo de prima";
datalines;
"Prima de Tarifa"
"Prima de Beneficios"
"Prima de Gastos"
;
*/

		proc sql;
			create table Pr_Ex6_tipo(tipo_prima char(40));
			insert into Pr_Ex6_tipo
				values("Prima de Tarifa")
				values("Prima de Beneficios")
				values("Prima de Gastos");
		quit;
		
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
		
		%visualizar(reserves=rslt.t_V_Ex6,premiums=rslt.Pr_Ex6,age=&x.,benefit=&bft.);
	%end;

%if "&example."="Ejemplo 7" %then;
%do;
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
%end;

%if "&example." = "Ejemplo 8 y 9" %then;
%do;
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
%end;

%mend;