{smcl}
{* *! version 1.0  14 Aug 2021}{...}
{viewerdialog fdrug "dialog fdrug"}{...}
{vieweralsosee "[D] fdrug" "mansection D fdrug"}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[P] display" "help display"}{...}
{vieweralsosee "[D] edit" "help edit"}{...}
{vieweralsosee "[P] tabdisp" "help tabdisp"}{...}
{vieweralsosee "[R] table" "help table"}{...}
{viewerjumpto "Syntax" "fdrug##syntax"}{...}
{viewerjumpto "Menu" "fdrug##menu"}{...}
{viewerjumpto "Description" "fdrug##description"}{...}
{viewerjumpto "Options" "fdrug##options"}{...}
{viewerjumpto "Remarks" "fdrug##remarks"}{...}
{viewerjumpto "Examples" "fdrug##examples"}{...}
{p2colset 1 13 15 2}{...}
{p2col:{bf:[D] fdrug} }Creates a binary variable (newvarname) flagging patients who received a specific drug and the date of first use (newvarname_sd) {p_end}


{marker syntax}{...}
{title:Syntax}

{p 8 14 2}
{opt fdrug} newvarname using if  [{cmd:,} {it:options}]

{synoptset 21 tabbed}{...}
{synopthdr}
{synoptline}

{syntab :Options}
{synopt :{opt minage(integer):}}drops medication events that occured before minage{p_end}
{synopt :{opt mindate(integer):}}drops medication events that occured before mindate. Default is 01/01/2011{p_end}
{synopt :{opt mindate(integer):}}drops medication events that occured after maxdate. Default is 01/07/2020 (closing date){p_end}
{synopt :{opt label(string):}}labels value 1 in newvarname with string{p_end}

{marker description}{...}
{title:Description}
{synoptset 21 tabbed}{...}
{synopt :{opt newvarname:}}name of new variable to be generated{p_end}
{synopt :{opt using:}}filename of medication claim table{p_end}
{synopt :{opt if:}}if statement selecting the relevant drugs. Variables used in if statement have to exist in the loaded dataset. Create dummy if necessary.{p_end}

{marker examples}{...}
{title:Examples}
{phang}{cmd: gen} med_id =""{p_end}
{phang}{cmd: fdrug} n07bc using "$clean/tblMED_ATC_N" if regexm(med_id, "N07BC"), minage(11) mindate(`=d(01/01/2011)') maxdate(`=d(01/07/2020)'){p_end}

				


