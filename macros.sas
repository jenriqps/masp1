/**********************************************************************
 * Notas de Clase de Matematicas Actuariales del Seguro de Personas I ;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
 **********************************************************************/
/********************
 * Macros
 *******************/

%macro seguroVitalicio(A=, B=, c=, i=, p=, x=);
* Macro para calcular la tabla de mortalidad Bowers;
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
	
	data trsf.ILTplus;
		set trsf.ILTplus;
		format l_x d_x comma32.0 q_x p_x e_x A_x aa_x comma32.8;
		label x="Edad"
		l_x = "Núm. de personas vivas de edad x" 
		d_x = "Núm. de muertos entre las edades x y x+1"
		q_x = "Probabilidad de que una persona de edad x, muera antes de cumplir o cumpliendo x+1 años"
		p_x = "Probabilidad de que una persona de edad x, muera después de la edad x+1"
		e_x = "Esperanza de vida"
		A_x = "Valor presente actuarial de un seguro vitalicio para (x)"
		aa_x = "Valor presente actuarial de una anualidad vitalicia para (x)";		
	run;
	
	proc datasets lib=work kill nolist;
	run;

%mend;

%macro visualizar(reserves=,premiums=,age=,benefit=);
* Macro para hacer visualizaciones (gráficas);
	title "Primas. &fecCal";
	proc print data=&premiums. label noobs;
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

	
	title "Proyección de Reservas. &fecCal";
	proc print data=&reserves. label noobs;
	run;
	title;

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

%macro examplesChapter7(example=,i=,x=,bft=,fxExp=,pcExp=,fxInitExp=,fxFinExp=,G=,n=,unitBft=,fxExpXunitBft=,fxExpXunitG=,pcInitExp=);
* Macro para hacer los ejemplos de prima de tarifa de las notas de clase;
%let A=0.0007;
%let B=0.00005;
%let c= 1.096478196143;
%let p=1000;
%let xmax=110;
%seguroVitalicio(A=&A., B=&B., c=&c., i=&i_., p=&p., x=&xmax.);

* Implementamos la solución en proc iml;

%if "&example."="Ejemplo 6" %then
	%do;
		* Ejemplo 6;
		proc iml;
			edit trsf.iltplus;
			read all var _NUM_ into ILTplus[colname=numVars];
			close input.iltplus;
			* Prima de tarifa;
			G6=(&fxExp.*ILTplus[&x.+1, "aa_x"]+&bft.*ILTplus[&x.+1, 
				"A_x"])/((1-&pcExp.)*ILTplus[&x.+1, "aa_x"]);
			*print G6;
			* Prima neta;
			P6=(&bft.*ILTplus[&x.+1, "A_x"])/(ILTplus[&x.+1, "aa_x"]);
			*print P6;
			* Prima de gastos;
			E6=G6-P6;
			*print E6;
			namesRow={"Prima de Tarifa","Prima de Beneficios","Prima de Gastos"};
			namesCol={"Tipo de Prima" "Monto"};
			Pr=t(G6||P6||E6)||t(G6||P6||E6)/G6;
			*print Pr;
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

%if "&example."="Ejemplo 7" %then
	%do;
		
		* Implementamos la solución en proc iml;
		proc iml;
			edit trsf.iltplus;
			read all var _NUM_ into ILTplus[colname=numVars];
			close input.iltplus;
			* Beneficio;
			bft=(&G.*ILTplus[&x.+1,"aa_x"]*(1-&pcExp.)-&fxInitExp.-&fxFinExp.*ILTplus[&x.+1,"A_x"])/ILTplus[&x.+1,"A_x"];
			*print bft;
			call symputx('bft',bft);
			* Prima neta;
			P=(bft*ILTplus[&x.+1, "A_x"])/(ILTplus[&x.+1, "aa_x"]);
			*print P;
			* Prima de gastos;
			E=&G.-P;
			*print E;
			namesRow={"Prima de Tarifa","Prima de Beneficios","Prima de Gastos"};
			namesCol={"Tipo de Prima" "Monto"};
			Pr=t(&G.||P||E)||t(&G.||P||E)/&G.;
			*print Pr;
		
			* Reservas;
			m=max(ILTplus[, "x"]-&x.);
			t_V=j(m, 5, 0);
		
			do t=0 to m-1;
				t_V[t+1, 1]=&x.+t;
				t_V[t+1, 2]=t;
				t_V[t+1, 3]=bft*ILTplus[&x.+1+t, "A_x"]-P*ILTplus[&x.+1+t, "aa_x"];
				t_V[t+1, 4]=(bft+&fxFinExp)*ILTplus[&x.+1+t, "A_x"]+&fxExp.*ILTplus[&x.+1+t, 
					"aa_x"]+&pcExp.*&G.*ILTplus[&x.+1+t, "aa_x"]-&G.*ILTplus[&x.+1+t, "aa_x"];
				if t=0 then t_V[t+1, 4]=t_V[t+1, 4]+&fxInitExp.;
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
		proc sql;
			create table Pr_Ex7_tipo(tipo_prima char(40));
			insert into Pr_Ex7_tipo
				values("Prima de Tarifa")
				values("Prima de Beneficios")
				values("Prima de Gastos");
		quit;
		
		
		data rslt.Pr_Ex7;
			set Pr_Ex7_tipo;
			set Pr_Ex7;
			label tipo_prima = "Tipo de Prima";
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
		
		%visualizar(reserves=rslt.t_V_Ex7,premiums=rslt.Pr_Ex7,age=&x.,benefit=&bft.);
	%end;

%if "&example." = "Ejemplo 8 y 9" %then
	%do;
		
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
			%put &x. &n.;
			G=(&fxInitExp.+((1+&fxExpXunitBft./&unitBft.)*&bft.+&fxFinExp.)*end(&x.,&n.,&i.,ILTplus)+
			(&fxExp.+&fxExpXunitG./&unitBft.*&bft.)*termAn(&x.,&n.,&i.,ILTplus))
				/((1-&pcExp.)*termAn(&x.,&n.,&i.,ILTplus)-(&pcInitExp.-&pcExp.));	
			*print G;
			* Prima neta;
			P=&bft.*end(&x.,&n.,&i.,ILTplus)/termAn(&x.,&n.,&i.,ILTplus);
			*print P;
			
			* Prima de gastos;
			E=G-P;
			*print E;
			namesRow={"Prima de Tarifa","Prima de Beneficios","Prima de Gastos"};
			namesCol={"Tipo de Prima" "Monto"};
			Pr=t(G||P||E)||t(G||P||E)/G;
			*print Pr;
			* Reservas;
			m=&n.+1;
			t_V=j(m, 5, 0);
		
			do t=0 to m-1;
				t_V[t+1, 1]=&x.+t;
				t_V[t+1, 2]=t;
				t_V[t+1, 3]=&bft.*end(&x.+t,&n.-t,&i.,ILTplus)-P*termAn(&x.+t,&n.-t,&i.,ILTplus);
				t_V[t+1, 4]=((1+&fxExpXunitBft./&unitBft.)*&bft.+&fxFinExp.)*end(&x.+t,&n.-t,&i.,ILTplus)
				+(&fxExp.+&fxExpXunitG./&unitBft.*&bft.)*termAn(&x.+t,&n.-t,&i.,ILTplus)+&pcExp.*G*termAn(&x.+t,&n.-t,&i.,ILTplus)
				-G*termAn(&x.+t,&n.-t,&i.,ILTplus);
				if t=0 then t_V[t+1, 4]=t_V[t+1, 4]+(&pcInitExp.-&pcExp.)*G+&fxInitExp.;
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
		proc sql;
			create table Pr_Ex8_tipo(tipo_prima char(40));
			insert into Pr_Ex8_tipo
				values("Prima de Tarifa")
				values("Prima de Beneficios")
				values("Prima de Gastos");
		quit;
		
		
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
		
		%visualizar(reserves=rslt.t_V_Ex8,premiums=rslt.Pr_Ex8,age=&x.,benefit=&bft.);
	%end;

%mend;

%macro portfolio(ds=,lt=,i=,m=);
* Macro para tarificar carteras;
	* Tasas de interés equivalentes;	
	data _null_;
		d=1-(1+&i.)**-1;
		im=&m.*((1+&i.)**(1/&m.)-1);
		dm=((1-d)**(1/&m.)-1)*(-&m.);
		call symputx('d',d);
		call symputx('im',im);
		call symputx('dm',dm);
	run;
	* Identificamos los tipos de productos;
	proc sql;
		create table work.prod1 as
			select *
			from &ds.
			where lowcase(product)="seguro vitalicio"
			;
		create table work.prod2 as
			select *
			from &ds.
			where lowcase(product)="anualidad vitalicia diferida"
			;		
	quit;
	* Seguro vitalicio pagadero al momento de la muerte;
	%if %sysfunc(exist(work.prod1)) %then 
		%do;
			proc sql;
				create table rslt.portf_pricing_1 as
				select 
				a.*
				, &i./log(&i.+1)*b.A_x*a.benefit format dollar32.2 as premium label="Premium"
				from work.prod1 a inner join &lt. b on (a.age = b.x)
				where lowcase(product)="seguro vitalicio"
				;
			quit;
		%end;
	* Anualidad vitalicia diferida pagadera m veces al año;
	%if %sysfunc(exist(work.prod2)) %then 
		%do;
			proc sql;
				create table rslt.portf_pricing_2 as
				select 
				a.*
				, b.l_x/c.l_x*(1+&i.)**(-(a.retirement_age-a.age))*(b.aa_x*&i.*&d./(&im.*&dm.)-(&i.-&im.)/(&im.*&dm.))*a.benefit format dollar32.2 as premium label="Premium"
				from work.prod2 a inner join &lt. b on (a.retirement_age = b.x) 
				inner join &lt. c on (a.age = c.x)			
				where lowcase(product)="anualidad vitalicia diferida"
				;
			quit;
		%end;
	* Limpiamos work;
	proc datasets lib=work kill nolist;
	run;
%mend;

%macro tablaDickson(A=,B=,c=,c2=,l_radix=,x_radix=,x_end=,i=);
	* Cálculo de la tabla Dickson;
	proc iml;
		* Creamos la matriz que contendrá la tabla;
		SLT=j(&x_end.-&x_radix.+1,9,0);
		* Creamos llenamos con edades y número de vivos;
		do x=&x_radix. to &x_end. by 1;
			SLT[x-&x_radix.+1,1]=x;
			SLT[x-&x_radix.+1,2]=x-2;
			if x=&x_radix. then
				SLT[x-&x_radix.+1,3]=&l_radix.;
			else
			do;
				/*l_x+2*/
				SLT[x-&x_radix.+1,3]=&l_radix.*exp(-&A.*(SLT[x-&x_radix.+1,1]-SLT[1,1])-&B./log(&c.)*&c.**SLT[1,1]*(&c.**(SLT[x-&x_radix.+1,1]-SLT[1,1])-1));
				if x >= &x_radix.+2 then
					do;
						/*l_[x]*/
						SLT[x-&x_radix.+1,4]=SLT[x-&x_radix.+1,3]/exp((1-&c2.**2)/log(&c2.)*&A.+(&c.**2-&c2.**2)/log(&c2./&c.)*&B.*&c.**SLT[x-&x_radix.+1,2]);
						/*l_{[x]+1}*/
						SLT[x-&x_radix.+1,5]=SLT[x-&x_radix.+1,4]*exp(&c2.*((1-&c2.)/log(&c2.)*&A.+(&c.-&c2.)/log(&c2./&c.)*&B.*&c.**SLT[x-&x_radix.+1,2]));
					end;
			end;
		end;
		* Agregamos la probabilidad anual de muerte;
		do x=&x_radix. to &x_end. by 1;
			/*q_{x+2}*/		
			if x=&x_end. then 
				do;		
					SLT[x-&x_radix.+1,6]=1;
				end;
			else
				SLT[x-&x_radix.+1,6]=(SLT[x-&x_radix.+1,3]-SLT[x-&x_radix.+2,3])/SLT[x-&x_radix.+1,3];
				
		end;
		* Agregamos los VPA de anualidades vitalicicias;
		do x=&x_end. to &x_radix. by -1;
					
			if x=&x_end. then 
				do;		
					SLT[x-&x_radix.+1,7]=1;
					/* aa_{[x]+1} */
					SLT[x-&x_radix.+1,8]=1+1/(1+&i.)*SLT[x-&x_radix.+1,3]/SLT[x-&x_radix.+1,5]*SLT[x-&x_radix.+1,7];
					/* aa_{[x]} */
					SLT[x-&x_radix.+1,9]=1+1/(1+&i.)*SLT[x-&x_radix.+1,5]/SLT[x-&x_radix.+1,4]*SLT[x-&x_radix.+1,8];			
				end;
			else
				do;
					/*aa_{x+2}*/
					SLT[x-&x_radix.+1,7]=1+1/(1+&i.)*(1-SLT[x-&x_radix.+1,6])*SLT[x-&x_radix.+2,7];
					if x >= &x_radix.+2 then
						do;
							if x >= &x_radix.+2 then
								do;
									/* aa_{[x]+1} */
									SLT[x-&x_radix.+1,8]=1+1/(1+&i.)*SLT[x-&x_radix.+1,3]/SLT[x-&x_radix.+1,5]*SLT[x-&x_radix.+1,7];
									/* aa_{[x]} */
									SLT[x-&x_radix.+1,9]=1+1/(1+&i.)*SLT[x-&x_radix.+1,5]/SLT[x-&x_radix.+1,4]*SLT[x-&x_radix.+1,8];
								end;
						end;
				end;
		end;
		* Guardamos la tabla como un dataset;
		create trsf.SLT from SLT[colname={"x_p_2", "x", "l_x_p_2", "l_x", "l_x_p_1", 
				"q_x_p_2", "aa_x_p_2", "aa_x_p_1","aa_x"}];
			append from SLT;
			close trsf.SLT;	
		
	run;
	
	* Damos formato y etiquetas a las variables;
	
	data trsf.SLT;
		format 
		x_p_2 x 3. 
		l_x l_x_p_1 l_x_p_2 comma32.2 
		q_x_p_2 aa_x aa_x_p_1 aa_x_p_2 comma32.6;
		label 
		x_p_2="x+2"
		x="x"
		l_x_p_2="l_x+2"
		l_x="l_[x]"
		l_x_p_1="l_[x]+1"
		q_x_p_2="q_x+2"
		aa_x_p_2="ä_x+2"
		aa_x_p_1="ä_[x]+1"
		aa_x="ä_[x]"
		;
		set trsf.SLT;
	run;	


%mend;

