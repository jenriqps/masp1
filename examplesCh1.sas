/**********************************************************************
 * Notas de Clase de Matematicas Actuariales del Seguro de Personas I ;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/
%let origen=/folders/myfolders/masp1;
%include "&origen./configuration.sas";
options mprint mlogic minoperator fullstimer;
ods graphics / reset width=6.4in height=4.8in imagemap noborder;

title "Las siguientes cantidades se calculan con simulaciones, no con la aproximación de la distribución normal";
proc iml;
	* Modulo que recibe un número aleatorio de una distribución uniforme 
	y regresa el valor simulado de la distribución el ejercicio 2 Capítulo 1 de las notas.
	Se aplica el método de inversión para simular variables aleatorias;
	start simEx2Ch1(u);
		if u <= 0.85 then x=0;
		else if u < 0.985 then x=(((u-.985)/(-.135))**.5-1)*(-2000);
		else x=2000;
		return(x);
	finish;
	* Fijamos la semilla aleatoria de SAS para que los resultados sean replicables;
	call randseed(321);
	* Número de simulaciones;
	%let nSim=10000;
	* Declaramos las matrices que reciben las simulaciones de 100 pólizas;
	X=j(100,&nSim.);
	u=j(100,&nSim.);
	* Generamos los números aleatorios con distribución uniforme;
	u=randfun({100 &nSim.},"Uniform");
	* Obtenemos las simulaciones de la distribución del ejercicio;
	do i=1 to 100;
		do j=1 to &nSim.;
			X[i,j]=simEx2Ch1(u[i,j]);
		end;
	end;
	* Calculamos los promedios de las simulaciones para cada póliza;
	E=mean(X`);
	* Calculamos las varianzas de las simulaciones para cada póliza;
	V=var(X`);
	* Calculamos las simulaciones de S (tiene tantos elementos como simulaciones);
	S=X[+,];
	* Transponemos las matrices;
	St=S`;
	EX=E`;
	VX=V`;
	l1=12000+1.282*(13560000)**0.5;
	print "l1 = E[S]+1.282(Var(S))^0.5 =" l1;
	Stl1=St[loc(St<=l1)];
	nl1=nrow(Stl1);
	pl1=nl1/&nSim.;
	print "2.c Aproximar la probabilidad de que el monto agregado de los reclamos no rebase E[S] +1.282(Var(S))^0.5: P[S<=l1] =" pl1;
	call qntl(s95,St,0.95);
	print "2.c Encuentre una cantidad s0.95 tal que la probabilidad de que el monto agregado de reclamos no exceda s0.95 es 0.95: " s95;
	* Guardamos s95 en una macrovariable para usarla en una gráfica;
	call symputx('s95',round(s95,1),'G');
	* Guardamos las matrices en data sets que serán usados en gráficas;
	create trsf.S from St[colname={"SumaX"}];
	append from St;
	close trsf.S;		

	create trsf.EX from EX[colname={"EX"}];
	append from EX;
	close trsf.EX;		

	create trsf.VX from VX[colname={"VX"}];
	append from VX;
	close trsf.VX;		
run;
title;

* Damos formatos y etiquetas a los data sets;
data trsf.EX;
	set trsf.EX;
	label EX='Promedio de pérdidas simuladas'
	i='Póliza';
	i=_n_;
run;

data trsf.VX;
	set trsf.VX;
	format VX comma32.;
	label VX='Varianza muestral de las pérdidas simuladas'
	i='Póliza';
	i=_n_;
run;

data trsf.S;
	set trsf.S;
	format SumaX comma32.2;
	label SumaX='Suma de pérdidas simuladas';
run;

* Graficamos;
title "Histograma de las pérdidas acumuladas y su aproximación con la distribución normal";
proc sgplot data=trsf.S;
	histogram SumaX;
	density SumaX/type= normal(mu = 12000 sigma=3682.39) lineattrs=(color=red);
	refline &s95./axis=x label="S &s95." lineattrs=(color= green);
	refline 18057/axis=x label="N 18058" lineattrs=(color= orange);
	yaxis grid;
	xaxis grid;		
run;
title;

title "Simulaciones de la esperanza de X";
proc sgplot data=trsf.ex;
	series x=i y=EX/markers;
	refline 120/ axis=y label="E[X] = 120" lineattrs=(color= red);
	yaxis grid;
	xaxis grid;	
run;
title;

title "Simulaciones de la varianza de X";
proc sgplot data=trsf.vx;
	series x=i y=vX/markers;
	refline 135600/ axis=y label="Var(X) = 135,600" lineattrs=(color= red);
	yaxis grid;
	xaxis grid;		
run;
