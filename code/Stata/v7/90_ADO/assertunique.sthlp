{smcl}
{* *! version 1.1.0  06jan2021}{...}
{viewerdialog assertunique "dialog assertunique"}{...}
{vieweralsosee "[R] assertunique" "mansection R assertunique"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] histogram" "help histogram"}{...}
{viewerjumpto "Syntax" "assertunique##syntax"}{...}
{viewerjumpto "Menu" "assertunique##menu"}{...}
{viewerjumpto "Description" "assertunique##description"}{...}
{viewerjumpto "Options" "assertunique##options"}{...}
{viewerjumpto "Examples" "assertunique##examples"}{...}
{p2colset 1 18 20 2}{...}
{p2col:{bf:[R] assertunique}}Asserts that varlist uniquely identifies records in a dataset {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 18 2}
{cmd:assertunique}
{varlist}
{ifin}

    {hline}

{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse sp500.dta}{p_end}

{pstd}Spike plot{p_end}
{phang2}{cmd:. assertunique date}
{phang2}{cmd:. assertunique high}
 {phang2}{cmd:. assertunique high close}            		

