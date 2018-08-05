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