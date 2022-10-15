function calculate_client_share_total(){
    total = 0;
    for(let index = 0; ; index++){
        id = "partners_partner_partner_counties_attributes_"+index+"_client_share";
        element =  document.getElementById(id);
        if(!element){break;}
        total = total + parseInt(element.value);
    }
    //const total_div =     document.getElementById("partner_county_client_share_total");
    document.getElementById("partner_county_client_share_total").innerHTML =total;
    return total;
}