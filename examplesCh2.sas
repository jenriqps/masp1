/**********************************************************************
 * Notas de Clase de Matematicas Actuariales del Seguro de Personas I ;
 * Jose Enrique Perez ;
 * Facultad de Ciencias. Universidad Nacional Autónoma de México ;
 **********************************************************************/
options mprint mlogic minoperator fullstimer;
ods graphics / reset width=6.4in height=4.8in imagemap noborder;

%let origen1=/folders/myfolders/masp1;
%include "&origen1./configuration.sas";
%include "&origen1./extInputs.sas";
%include "&origen1./macros.sas";


* Parámetros de la tabla Bowers;
%let A=0.0007;
%let B=0.00005;
%let c= 1.096478196143;
%let i=0.06;
%let p=1000;
%let xmax=110;

* Generamos la tabla de vida enriquecida;
%seguroVitalicio(A=&A., B=&B., c=&c., i=&i., p=1000, x=&xmax.)



 



