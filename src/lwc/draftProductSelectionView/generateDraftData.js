export default function generateDraftData({ amountOfRecords }) {
    return [...Array(amountOfRecords)].map((_, index) => {
        return {
            //Product_Name__c,: 'Name (${index})',
//            Unit_Price__c: Math.floor(Math.random() * 50),
//            Order_Qty__c,: Math.floor(Math.random() * 20),
//            Promotion_Order_Qty__c,: Math.floor(Math.random() * 10),
//            Promotion_Free_Qty__c,: Math.floor(Math.random() * 10)
        };
    });
}