{smcl}
{* *! version 1.0.0  06jan2021}{...}
{viewerdialog listif "dialog listif"}{...}
{vieweralsosee "[D] listif" "mansection D listif"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[P] display" "help display"}{...}
{vieweralsosee "[D] edit" "help edit"}{...}
{vieweralsosee "[P] tabdisp" "help tabdisp"}{...}
{vieweralsosee "[R] table" "help table"}{...}
{viewerjumpto "Syntax" "listif##syntax"}{...}
{viewerjumpto "Menu" "listif##menu"}{...}
{viewerjumpto "Description" "listif##description"}{...}
{viewerjumpto "Options" "listif##options"}{...}
{viewerjumpto "Remarks" "listif##remarks"}{...}
{viewerjumpto "Examples" "listif##examples"}{...}
{p2colset 1 13 15 2}{...}
{p2col:{bf:[D] listif} }List values of variables of all records of a random sample of individuals if condition is true {p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{opt listif} [{it:{help varlist}}] {ifin} [{cmd:,} {it:options}]

{synoptset 21 tabbed}{...}
{synopthdr}
{synoptline}
{syntab :Required}
{synopt :{opt id(varname)}}varname of variable that identifies individuals in multiple-record ID dataset formats{p_end}
{synopt :{opt sort(varlist)}}varlist determining sorting of list

{syntab :Options}
{synopt :{opt n(integer)}}number of individuals listed, default is 10{p_end}
{synopt :{opt seed(integer)}}seed, seed can not be set to -88888{p_end}
{synopt :{opt nolab:el}}suppress value labels{p_end}

{marker examples}{...}
{title:Examples}

{phang}{cmd:. sysuse bplong.dta}{p_end}
{phang}{cmd:. listif patient sex agegrp when bp if bp==153, id(patient) sort(patient) sepby(patient when) n(5)}{p_end}



