


function calculate_client_share_total(){
    total = 0;
    const client_shares = document.querySelectorAll('*[id$="client_share"]')
    client_shares.forEach(
        cs => {
                if(!cs.value || cs.offsetWidth === 0){
                    return;
                }
                if(cs.value){
                    total += parseInt(cs.value)
                }
        }
    );
    document.getElementById("partner-county-client-share-total").innerHTML =total;

    if(total == 0 || total == 100){
        document.getElementById("partner-county-client-share-total-warning").style.visibility= 'hidden';
        document.getElementById("profile-update-button").style.visibility = 'visible';
        document.getElementById("profile-update-button-disabled").style.visibility = 'hidden';
        document.getElementById("partner-county-client-share-total-warning-footer").style.visibility= 'hidden';
    }else {
        document.getElementById("partner-county-client-share-total-warning").style.visibility= 'visible';
        document.getElementById("profile-update-button").style.visibility = 'hidden';
        document.getElementById("profile-update-button-disabled").style.visibility = 'visible';
        document.getElementById("partner-county-client-share-total-warning-footer").style.visibility= 'visible';


    }
    return total;
}

///TODO  I'm trying to get calculate_client_share_total to fire when we remove a partner/county.   This is not working
//   Reference:  https://github.com/nathanvda/cocoon


//Following the pattern from adjustments.js

$(document).on("cocoon:after-remove", function(){
    calculate_client_share_total();
});

