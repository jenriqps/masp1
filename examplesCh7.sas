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

%examplesChapter7(example=&example_.,i=&i_.,x=&x_.,bft=&bft_.,fxExp=&fxExp_.,pcExp=&pcExp_.)