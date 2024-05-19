const cases = document.querySelectorAll('.case');
const session4 = pl.create();
var rootUrl = window.location.origin;
var prologUrl = rootUrl + "/static/prolog/ia.pl"; 
session4.consult(prologUrl);

function format_query_chute() {
    
    var decodedQuery = document.createElement("textarea");
    decodedQuery.innerHTML = pl_query;
    var queryWithQuotes = decodedQuery.value;
    
    // Séparer la requête en parties
    const parts = queryWithQuotes.match(/\[.*?\]|[^[\]\s,]+/g);
    
    // Modifications des derniers arguments
    parts[parts.length - 3] = "X";
    parts[parts.length - 4] = parts[parts.length - 4] + "]"
    
    
    // Ajout des virgules
    const formattedQuery = parts.slice(1, parts.length - 2).join(", ");
    return parts[0] + formattedQuery + ").";
}

function select_card(IA_choice){
    var attribu = '.value[value="' + IA_choice + '"]';
    var card_selected = document.querySelector(attribu);
    if (card_selected) {
        card_selected.parentElement.classList.toggle('selected');
    } else {
        console.log("Aucune carte avec la valeur " + IA_choice + " n'a été trouvée.");
    }
}

document.getElementById("button_générer").addEventListener("click", function(event){
    event.preventDefault();
    
    session4.query(pl_query);
    
    session4.answer(x => {
        var card = x.links.Card;
        
        displayMessage("TBot : L'IA a choisit de se débarasser de la carte " + card + ".");
        displayMessage("TBot : Appuyez sur suivant pour continuer.");
        select_card(card);
        
        // Envoyer le résultat
        var formData = new FormData();
        formData.append('card', card);
        
        fetch('/chute', {
            method: 'POST',
            body: formData
        })
        .then((response) => response.json())
        .then((data) => {
            console.log(data);
        })
        .catch((error) => {
            console.log(error);
        });
        
    });
    
    // Mettre à jour les boutons
    var button_suivant = document.getElementById('button_suivant');
    var button_générer = document.getElementById('button_générer');

    button_suivant.style.pointerEvents = 'auto';
    button_générer.style.pointerEvents = 'none';
    button_suivant.style.opacity = "1";
    button_générer.style.opacity = "0.5"; 
});