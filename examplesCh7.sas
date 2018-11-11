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









