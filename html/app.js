const { ref } = Vue;

const app = Vue.createApp({
    data() {
        return {
            displayUi: false,
            rouletteData: [
                {
                    id: 0,
                    rarity: "legendary",
                    img: '/html/img/merc.png',
                    name: "Mercedes G63 AMG"
                },
                {
                    id: 1,
                    rarity: "epic",
                    img: '/html/img/supreme.webp',
                    name: "Supreme Backpack"
                },
                {
                    id: 2,
                    rarity: "rare",
                    img: '/html/img/knife.png',
                    name: "Knife"
                },
                {
                    id: 3,
                    rarity: "rare",
                    img: '/html/img/carplay.png',
                    name: "Carplay"
                },
                {
                    id: 4,
                    rarity: "common",
                    img: '/html/img/merc.png',
                    name: "Gucci Backpack"
                },
                {
                    id: 5,
                    rarity: "common",
                    img: '/html/img/cola.png',
                    name: "Coca Cola"
                },
                {
                    id: 6,
                    rarity: "common",
                    img: '/html/img/cash.png',
                    name: "$1000 cash"
                },
                {
                    id: 7,
                    rarity: "common",
                    img: '/html/img/iphone.webp',
                    name: "Iphone"
                },
            ],
            duplicatedData: [],
            firstElement: 0,
            probability: {
                legendary: 0.001,
                epic: 0.01,
                rare: 0.20,
                common: 0.789,
            }
        };
    },
    mounted() {
        this.listener = window.addEventListener("message", (event) => {
            if (event.data.type === "hud_settings") {
                
            }
        });

        this.initializeDisplayItems();
        this.initializeRoulette();
    },
    methods: {
        openSettings() {
            $("#settings-modal").modal("show");
        },
        closeSettings() {
            $("#settings-modal").modal("hide");
            $.post('https://complete_hud/closeSettings');
        },
        createDisplayItem(item) {
            
        },
        initializeDisplayItems() {
            var display = document.getElementById("displayItems");
            
            this.rouletteData.forEach((item) => {
                const colDiv = document.createElement("div");
                colDiv.classList.add("col");
                const itemDiv = document.createElement("div");
                itemDiv.classList.add(item.rarity);
                itemDiv.classList.add("img-responsive");
                itemDiv.classList.add("img-responsive-1x1");
                itemDiv.classList.add("rounded");
                itemDiv.classList.add("border");
                itemDiv.style.backgroundImage = `url(${item.img})`;
                itemDiv.style.backgroundSize = "contain";
                itemDiv.style.display = "flex";
                itemDiv.style.alignItems = "flex-end";
                itemDiv.style.position = "relative";
                itemDiv.style.justifyContent = "center";
                itemDiv.style.boxShadow = "inset 0px -57px 73px -28px rgb(0 0 0 / 86%)";

                const h3 = document.createElement("h3");
                h3.classList.add("text-center");
                h3.classList.add("text-white");
                h3.classList.add("text-shadow");
                h3.classList.add("text-uppercase");

                h3.style.position = "absolute";
                h3.style.marginBottom = "0.5rem";
                h3.style.fontWeight = "800";
                h3.style.lineHeight = "1.2";
                h3.innerText = item.name;
                itemDiv.appendChild(h3);

                colDiv.appendChild(itemDiv);
                display.appendChild(colDiv);
            });
        },
        createItemCard(item) {
            const itemDiv = document.createElement("div");
            itemDiv.classList.add("rouletteCard");
            itemDiv.classList.add(item.rarity);
            itemDiv.style.backgroundImage = `url(${item.img})`;
            itemDiv.style.backgroundSize = "contain";
            itemDiv.style.backgroundPosition = "center";
            itemDiv.style.backgroundRepeat = "no-repeat";
            itemDiv.alt = item.name;
            return itemDiv;
        },
        initializeRoulette() {
            //const svg = `<svg class="" version="1.1" xmlns="http://www.w3.org/2000/svg" width="174" height="200" viewBox="0 0 173.20508075688772 200" style="/* filter: drop-shadow(rgba(255, 255, 255, 0.5) 0px 0px 10px); */height: 10rem;width: 9rem;margin: 3px;/* border-radius: 15px; *//* border-bottom: 3px solid rgba(0, 0, 0, 0.2); */display: flex;flex-wrap: nowrap !important;align-items: center;justify-content: center;color: white;font-size: 1.5em;/* border: 3px solid #ffffff4a; */" stroke="#ffffff4a" stroke-width="8px"><path fill="#fff" d="M73.61215932167728 7.499999999999999Q86.60254037844386 0 99.59292143521044 7.499999999999999L160.21469970012114 42.5Q173.20508075688772 50 173.20508075688772 65L173.20508075688772 135Q173.20508075688772 150 160.21469970012114 157.5L99.59292143521044 192.5Q86.60254037844386 200 73.61215932167728 192.5L12.99038105676658 157.5Q0 150 0 135L0 65Q0 50 12.99038105676658 42.5Z"></path></svg>`

            var data = this.rouletteData;

            const numCopies = this.rouletteData.length * 2;

            const duplicatedData = [];

            while (duplicatedData.length < numCopies * this.rouletteData.length) {
                // generete an item randomly based on probability
                const rand = Math.random();
                let cumulativeProbability = 0;

                for (const key in this.probability) {
                    cumulativeProbability += this.probability[key];
                    if (rand <= cumulativeProbability) {
                        const rarity = key;
                        const items = data.filter(item => item.rarity === rarity);
                        const selectedItem = items[Math.floor(Math.random() * items.length)];
                        duplicatedData.push(selectedItem);
                        break;
                    }
                }
            }

            duplicatedData.sort(() => Math.random() - 0.5);
            console.log(duplicatedData.length);
            data = duplicatedData;
            this.duplicatedData = duplicatedData;

            const roulette = document.getElementById("rouletteItems");
            const itemsPerRow = this.rouletteData.length; // Numero di elementi per riga

            var firstIds = [];
            var lastIds = [];
            for (let i = 0; i < data.length; i += itemsPerRow) {
                const row = document.createElement("div");
                row.classList.add("rowCard");

                // Prendi un sottoinsieme di elementi per la riga corrente
                const rowItems = data.slice(i, i + itemsPerRow);

                rowItems.forEach((item) => {
                    const itemDiv = this.createItemCard(item);
                    if (i == itemsPerRow) {
                        itemDiv.dataset.id = `${item.id}_first`;
                        firstIds.push(item.id);
                    } else if (i == data.length - itemsPerRow * 2 && !lastIds.includes(item.id)) {
                        itemDiv.dataset.id = `${item.id}_last`;
                        lastIds.push(item.id);
                    }
                    row.appendChild(itemDiv);
                });
                roulette.appendChild(row);
            }

            const selectedItemId = firstIds[Math.floor(Math.random() * firstIds.length)];
            const selectedElement = roulette.querySelector(`[data-id="${selectedItemId}_first"]`);
            console.log(selectedItemId, selectedElement);
            const rouletteRect = roulette.getBoundingClientRect();
            const selectedRect = selectedElement.getBoundingClientRect();

            const moveDistance = rouletteRect.left - selectedRect.left + roulette.clientWidth / 2 - selectedRect.width / 2;

            roulette.style.transform = `translateX(${moveDistance}px)`;
            this.firstElement = this.getNumericTransformXValue(roulette);
        },
        getNumericTransformXValue(element) {
            const styles = window.getComputedStyle(element);
            const transformMatrix = new DOMMatrix(styles.transform);
            return transformMatrix.m41;
        },
        spinRoulette() {
            /*
            var selectedItem = null;
            var rarity = null;

            // get random rarity based on probability
            const rand = Math.random();            
            let cumulativeProbability = 0;

            for (const key in this.probability) {
                cumulativeProbability += this.probability[key];
                if (rand <= cumulativeProbability) {
                    rarity = key;
                    break;
                }
            }

            // get random item from rarity
            var data = this.rouletteData;
            var items = data.filter(item => item.rarity === rarity);
            selectedItem = items[Math.floor(Math.random() * items.length)];
            const selectedItemId = selectedItem.id;
            */

            const selectedItemId = Math.floor(Math.random() * this.rouletteData.length);
            const selectedItem = this.rouletteData[selectedItemId];
            this.animateRoulette(selectedItem, selectedItemId);
        },
        animateRoulette(selectedItem, selectedItemId) {
            const roulette = document.getElementById("rouletteItems");
            const selectedElement = roulette.querySelector(`[data-id="${selectedItemId}_last"]`);
            const rouletteRect = roulette.getBoundingClientRect();
            const selectedRect = selectedElement.getBoundingClientRect();
            const selectedWidth = selectedElement.offsetWidth / 2.3;

            // get a random value between -selectedWidth and selectedWidth
            const randomValue = Math.floor(Math.random() * selectedWidth) * (Math.round(Math.random()) ? 1 : -1)

            var moveDistance = rouletteRect.left - selectedRect.left + roulette.clientWidth / 2 - selectedRect.width / 2;
            moveDistance += randomValue;

            // disable button
            document.getElementById("spinButton").classList.add("disabled");
            document.getElementById("spinButton").classList.add("btn-loading");

            const id = `${selectedItemId}_last`;
                        
            gsap.to(roulette, {
                duration: 9,
                x: `${moveDistance}`,
                ease: "power4.out",
                onComplete: function() {
                    const items = document.getElementById("rouletteItems");
                    items.style.transform = 'none';

                    /*
                    // delete all items except ${selectedItemId}_last
                    const allItems = document.querySelectorAll(".rouletteCard");
                    allItems.forEach(item => {
                        if (item.dataset.id !== id) {
                            item.remove();
                        }
                    });

                    // remove div rowCard empty
                    const rowCards = document.querySelectorAll(".rowCard");
                    rowCards.forEach(row => {
                        if (row.innerHTML === "") {
                            row.remove();
                        }
                    });

                    // add h3 with item name to selected item
                    const winItem = document.querySelector(`[data-id="${id}"]`);
                    const h3 = document.createElement("h3");
                    h3.classList.add("text-center");
                    h3.classList.add("text-white");
                    h3.classList.add("text-shadow");
                    h3.classList.add("text-uppercase");
                    h3.style.position = "absolute";
                    h3.style.marginBottom = "0.5rem";
                    h3.style.fontWeight = "800";
                    h3.style.lineHeight = "1.2";
                    h3.innerText = selectedItem.name;
                    winItem.appendChild(h3);
                    */

                    // create item card and add it to modalBody
                    const itemCard = document.createElement("div");
                    itemCard.classList.add("rouletteCard");
                    itemCard.classList.add(selectedItem.rarity);
                    itemCard.style.backgroundImage = `url(${selectedItem.img})`;
                    itemCard.style.backgroundSize = "contain";
                    itemCard.style.backgroundPosition = "center";
                    itemCard.style.backgroundRepeat = "no-repeat";
                    itemCard.alt = selectedItem.name;
                    itemCard.style.height = "10rem";
                    itemCard.style.width = "10rem";
                    itemCard.style.display = "flex";
                    itemCard.style.alignItems = "center";
                    itemCard.style.justifyContent = "center";
                    itemCard.style.position = "relative";
                    itemCard.style.boxShadow = "inset 0px -57px 73px -28px rgb(0 0 0 / 86%)";

                    const h3 = document.createElement("h3");
                    h3.classList.add("text-center");
                    h3.classList.add("text-white");
                    h3.classList.add("text-shadow");
                    h3.classList.add("text-uppercase");
                    h3.style.position = "absolute";
                    h3.style.marginBottom = "0.5rem";
                    h3.style.fontWeight = "800";
                    h3.style.lineHeight = "1.2";
                    h3.innerText = selectedItem.name;
                    itemCard.appendChild(h3);

                    const modalBody = document.getElementById("modalBody");
                    modalBody.innerHTML = "";
                    modalBody.appendChild(itemCard);

                    // opne rewar-modal
                    $("#reward-modal").modal("show");
                    

                    document.getElementById("spinButton").classList.remove("disabled");

                    // set button text with 24 hours countdown
                    document.getElementById("spinButton").innerText = "Spin (24h)";
                }
            });
        }        
    }
});

app.mount("#app");