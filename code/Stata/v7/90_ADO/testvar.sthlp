{smcl}
{* *! * version 1.1  AH 20 Aug 2021  }{...}
{viewerdialog testvar "dialog testvar"}{...}
{vieweralsosee "[D] testvar" "mansection D testvar"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[P] display" "help display"}{...}
{vieweralsosee "[D] edit" "help edit"}{...}
{vieweralsosee "[P] tabdisp" "help tabdisp"}{...}
{vieweralsosee "[R] table" "help table"}{...}
{viewerjumpto "Syntax" "testvar##syntax"}{...}
{viewerjumpto "Menu" "testvar##menu"}{...}
{viewerjumpto "Description" "testvar##description"}{...}
{viewerjumpto "Options" "testvar##options"}{...}
{viewerjumpto "Remarks" "testvar##remarks"}{...}
{viewerjumpto "Examples" "testvar##examples"}{...}
{p2colset 1 20 15 2}{...}
{p2col:{bf:[D] testvar} }Reports global p-value for categorical predictor after estimation command {p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{opt testvar} varname [{cmd:,} {it:options}]

{synoptset 21 tabbed}{...}
{synopthdr}
{synoptline}

{syntab :Options}
{synopt :{opt global:}}save p-value in global macro p_varname {p_end}
{synopt :{opt format(string):}}format p-value according to Stata format specified in string{p_end}

{marker Examples}{...}
{title:Examples}

{phang}{cmd:. sysuse auto}{p_end}
{phang}{cmd:. regress price i.foreign} {p_end}
{phang}{cmd:. testvar foreign, format(%5.3fc) global} {p_end}
		 
{marker author}{...}
{title:Author}
{pstd}
Andreas Haas, Email: andreas.haas@ispm.unibe.ch

