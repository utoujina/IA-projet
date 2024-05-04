const cards = document.querySelectorAll('.card');
const cases = document.querySelectorAll('.case');


// Déséllectionne les élément sauf celui en paramètre
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

// Event pour les cases
cases.forEach(caseElement => {
    caseElement.addEventListener('click', () => {
        deselectExcept(caseElement, cases);
        caseElement.classList.toggle('selected');
    });
    
});

// Fonction du bouton d'envoie
function submit_player_choice() {
    const card_selected = document.querySelector('.card.selected');
    const case_selected = document.querySelector('.case.selected');
    
    var button_suivant = document.getElementById('button_suivant');
    var button_submit = document.getElementById('button_submit');

    // Vérifier si une carte et une case sont sélectionnées
    if (card_selected && case_selected) {
        
        // Envoyer les éléments sélectionnés au backend via une requête Fetch
        var formData = new FormData();
        formData.append('card', card_selected.querySelector('.value').getAttribute('value'));
        formData.append('case', case_selected.querySelector('.value').getAttribute('value'));
        
        fetch('/Human_choice', {
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
    }
    else{
        alert("Veuillez sélectionner une carte et une case.");
    }
}