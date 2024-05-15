const cards = document.querySelectorAll('.card');

function deselectExcept(selectedElement, elements) {
    elements.forEach(element => {
        if (element !== selectedElement) {
            element.classList.remove('selected');
        }
    });
}

// Event pour les cartes
cards.forEach(card => {
    card.addEventListener('click', () => {
        deselectExcept(card, cards);
        card.classList.toggle('selected');
    });
});

// Fonction du bouton d'envoie
function submit_player_choice() {
    const card_selected = document.querySelector('.card.selected');
    
    var button_suivant = document.getElementById('button_suivant');
    var button_submit = document.getElementById('button_submit');

    // Vérifier si une carte et une case sont sélectionnées
    if (card_selected) {
        
        var card_value = card_selected.querySelector('.value').getAttribute('value');
        
        // Envoyer les éléments sélectionnés au backend via une requête Fetch
        var formData = new FormData();
        formData.append('card', card_value);
        
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
        
        // Mettre à jour les boutons
        button_suivant.style.pointerEvents = 'auto';
        button_submit.style.pointerEvents = 'none';
        button_suivant.style.opacity = "1";
        button_submit.style.opacity = "0.5";
        
        displayMessage("TBot : Vous avez choisit de vous débarasser de la carte " + card_value + ".");
    }
    else{
        alert("Veuillez sélectionner une carte.");
    }
}