export default function generateData({ amountOfRecords }) {
    return [...Array(amountOfRecords)].map((_, index) => {
        return {
            ProductName: `Name (${index})`,
            UnitPrice: Math.floor(Math.random() * 50),
            OrderQty: Math.floor(Math.random() * 20),
            FreeQty: Math.floor(Math.random() * 5),
            PromoOrderQty: Math.floor(Math.random() * 10),
            PromoFreeQty: Math.floor(Math.random() * 10)
        };
    });
}