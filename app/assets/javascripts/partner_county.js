function calculate_client_share_total(){
    total = 0;
    const client_shares = document.querySelectorAll('*[id$="client_share"]')
    client_shares.forEach(
        cs => {
            if (cs.value) {
                total += parseInt(cs.value)
            }
        }
        );
    document.getElementById("partner_county_client_share_total").innerHTML =total;
    if(total == 0 || total == 100){
        document.getElementById("partner_county_client_share_total_warning").style.visibility= 'hidden';
    }else {
        document.getElementById("partner_county_client_share_total_warning").style.visibility= 'visible';
    }
    return total;
}