/**********************************************************************
* Notas de Clase de Matematicas Actuariales del Seguro de Personas I ;
* Jose Enrique Perez ;
* Facultad de Ciencias. Universidad Nacional Autonoma de Mexico ;
**********************************************************************/

/*******************
/* Extracción de Insumos ;
*******************/

%let origen=/folders/myfolders/masp1;
%include "&origen./configuration.sas";

%web_drop_table(WORK.IMPORT);

* Importación de la tabla de mortalidad ;
FILENAME REFFILE1 "&origen./inputs/files/ilt.xlsx";

PROC IMPORT DATAFILE=REFFILE1
	DBMS=XLSX
	OUT=WORK.ilt;
	GETNAMES=YES;
RUN;

%web_open_table(WORK.IMPORT);

data input.ilt;
	format age comma3. l_x d_x comma30.2;
	set WORK.ilt;
	label age = "Age"
		l_x = "Number of lives at age x"
		d_x = "Number of deaths when age x";	
run;

* Importación de la cartera de seguros;
FILENAME REFFILE2 "&origen./inputs/files/portfolio.xlsx";

PROC IMPORT DATAFILE=REFFILE2
	DBMS=XLSX
	OUT=WORK.portfolio replace;
	GETNAMES=YES;
RUN;

%web_open_table(WORK.IMPORT);

data input.portfolio;
	format age comma3. benefit dollar30.2;
	set WORK.portfolio;
	label age = "Edad"
		id_insured = "ID del asegurado"
		benefit = "Suma asegurada"	
		product = "Tipo de producto"
		payment_form = "Forma de pago"		
		;
		
run;

* Importación de la cartera de pensiones;
FILENAME REFFILE3 "&origen./inputs/files/portfolio_02.xlsx";

PROC IMPORT DATAFILE=REFFILE3
	DBMS=XLSX
	OUT=WORK.portfolio_02 replace;
	GETNAMES=YES;
RUN;

%web_open_table(WORK.IMPORT);

data input.portfolio_02;
	format age comma3. benefit dollar30.2;
	set WORK.portfolio_02;
	label age = "Edad"
		id_insured = "ID del pensionado"
		benefit = "Pensión Anual"	
		product = "Tipo de producto"
		retirement_age = "Edad de retiro"
		freq_pymt_year = "Frecuencia de pago"
		payment_form = "Forma de pago"		
		;
		
run;

* Importación de la experiencia de los factores de riesgo para ejemplo de asset shares;
FILENAME REFFILE4 "&origen./inputs/files/assetShareAssumptions.xlsx";

PROC IMPORT DATAFILE=REFFILE4
	DBMS=XLSX
	OUT=WORK.assetShareAssmpts replace;
	GETNAMES=YES;
RUN;

%web_open_table(WORK.IMPORT);

data input.assetShareAssmpts;
	format t comma3. interest mortality_rate annual_exp  percentn10.4 pymt_ben_exp dollar10.2 ;
	set WORK.assetShareAssmpts;
	label t = "Tiempo (años)"
		interest = "Tasa de interés"
		mortality_rate = "Tasa de mortalidad"	
		annual_exp = "Gastos anuales (% de la prima)"
		pymt_ben_exp = "Gastos por pago de beneficio"
		;		
run;

