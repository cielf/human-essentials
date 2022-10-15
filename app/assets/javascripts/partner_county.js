function calculate_client_share_total(){
    total = 0;
    const client_shares = document.querySelectorAll('*[id$="client_share"]')
    client_shares.forEach(cs => total += parseInt(cs.value));
    document.getElementById("partner_county_client_share_total").innerHTML =total;
    return total;
}