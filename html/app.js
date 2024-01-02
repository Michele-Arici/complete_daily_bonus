const { ref } = Vue;

const app = Vue.createApp({
    data() {
        return {
            displayUi: false,
            rouletteData: [],
            duplicatedData: [],
            firstElement: 0,
            probability: {}
        };
    },
    mounted() {
        this.listener = window.addEventListener("message", (event) => {
            if (event.data.type === "dailyBonus") {
                if (event.data.action === "initialize") {
                    console.log("initialize");
                    this.probability = event.data.probability;
                    this.rouletteData = JSON.parse(event.data.rouletteData);
                    this.initializeDisplayItems();
                    this.initializeRoulette();
                } else if (event.data.action === "open") {
                    this.displayUi = true;
                } else if (event.data.action === "close") {
                    this.displayUi = false;
                } else if (event.data.action === "setData") {
                    eval(`this.${event.data.setting} = "${event.data.value}"`);
                }
            }
        });

        window.addEventListener("keyup", (event) => {
            if (event.key === "Escape") {
                this.closeSettings();
            }
        });
    },
    methods: {
        openSettings() {
            $("#settings-modal").modal("show");
        },
        closeSettings() {
            $("#settings-modal").modal("hide");
            $.post('https://complete_hud/closeSettings');
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
                itemDiv.style.boxShadow = "inset 0px -57px 73px -28px rgb(0 0 0 / 85%)";

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
            var data = this.rouletteData;

            const numCopies = this.rouletteData.length * 2;

            const duplicatedData = [];
            for (let i = 0; i < numCopies; i++) {
                data.sort(() => Math.random() - 0.5);
                duplicatedData.push(...data);
            }

            data = duplicatedData;
            this.duplicatedData = duplicatedData;

            const roulette = document.getElementById("rouletteItems");
            const itemsPerRow = this.rouletteData.length;

            for (let i = 0; i < data.length; i += itemsPerRow) {
                const row = document.createElement("div");
                row.classList.add("rowCard");

                const rowItems = data.slice(i, i + itemsPerRow);

                rowItems.forEach((item) => {
                    const itemDiv = this.createItemCard(item);
                    if (i == itemsPerRow) {
                        itemDiv.dataset.id = `${item.id}_first`;
                    } else if (i == data.length - itemsPerRow * 2) {
                        itemDiv.dataset.id = `${item.id}_last`;
                    }
                    row.appendChild(itemDiv);
                });
                roulette.appendChild(row);
            }

            const selectedItemId = Math.floor(Math.random() * this.rouletteData.length);
            const selectedElement = roulette.querySelector(`[data-id="${selectedItemId}_first"]`);
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
                    

                    document.getElementById("spinButton").classList.remove("disabled");

                    // set button text with 24 hours countdown
                    document.getElementById("spinButton").innerText = "Spin (24h)";
                }
            });
        }        
    }
});

app.mount("#app");