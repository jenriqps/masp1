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

* Creamos macrovariables ;

* Ejemplo 6;
/*
%let fecCal=01Dec2018;
%let example_=Ejemplo 6;
%let i_=0.06;
%let x_=40;
%let bft_=1000;
%let fxExp_=5;
%let pcExp_=0.1;
%let fxInitExp=0;
%let fxFinExp=0;
%let G=0;
%let n=0;
%let unitBft=0;
%let fxExpXunitBft=0;
%let fxExpXunitG=0;
%let pcInitExp=0;
*/


* Ejemplo 7;
/*
%let fecCal=01Dec2018;
%let example_=Ejemplo 7;
%let i_=0.06;
%let x_=40;
%let bft_=0;
%let fxExp_=0;
%let pcExp_=0.1;
%let fxInitExp=20;
%let fxFinExp=80;
%let G=30;
%let n=0;
%let unitBft=0;
%let fxExpXunitBft=0;
%let fxExpXunitG=0;
%let pcInitExp=0;
*/

* Ejemplo 8 y 9;
/*
%let fecCal=01Dec2018;
%let example_=Ejemplo 8 y 9;
%let i_=0.06;
%let x_=50;
%let bft_=1000;
%let fxExp_=5;
%let pcExp_=0.05;
%let fxInitExp=20;
%let fxFinExp=80;
%let G=0;
%let n=10;
%let unitBft=1000;
%let fxExpXunitBft=10;
%let fxExpXunitG=2;
%let pcInitExp=0.5;
*/

%examplesChapter7(example=&example_.,i=&i_.,x=&x_.,bft=&bft_.,fxExp=&fxExp_.,pcExp=&pcExp_.,fxInitExp=&fxInitExp.,fxFinExp=&fxFinExp.,G=&G.,n=&n.,unitBft=&unitBft.,fxExpXunitBft=&fxExpXunitBft.,fxExpXunitG=&fxExpXunitG.,pcInitExp=&pcInitExp.)
;

