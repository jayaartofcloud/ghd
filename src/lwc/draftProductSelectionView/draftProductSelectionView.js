/**
 * Created by Jayakumar Mogenahall on 22/02/2023.
 */

import { LightningElement,wire,api } from 'lwc';
//import datatableStyles from '@salesforce/resourceUrl/Ghd_Styles';
import getDraftViewForCustomer from '@salesforce/apex/OrderDraftService.getDraftViewForCustomer';
//import generateData from './generateDraftData';


const draftColumns = [
     { label: 'Draft Name', fieldName: 'DraftRecordName', editable: false },
     {label: 'Description', fieldName:'Description', editable: false },
//    { label: 'Product Name', fieldName: 'ProductName', editable: false },
    { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency', editable: false, typeAttributes:{currencyCode: 'GBP'}},
    { label: 'Total Value', fieldName: 'TotalAmount', type: 'currency', editable: false, typeAttributes:{currencyCode: 'GBP'}},
    {label: 'Last Modified By', fieldName: 'LastModifiedBy', editable:false},
	{label: 'Last Modified Date', fieldName: 'LastModifiedDate', editable:false}
];

export default class DraftProductSelectionView extends LightningElement {
data = [];
@api recordId;
draftColumns = draftColumns;
selectedRow;

connectedCallback() {
		console.log('recordId:'+this.recordId);
		getDraftViewForCustomer({customerId:this.recordId}).then(result =>{
		      console.log('#result draft:'+JSON.stringify(result))
		      if(result){
		            this.data = result;
       		 }});
	}
handleRowSelected(event){
    alert(JSON.stringify(event.detail.selectedRows))
    event.preventDefault();
    console.log('row changed')
    const selectedRows = event.detail.selectedRows;
    console.log('selectedRows:' + JSON.stringify(selectedRows))
    this.selectedRow = selectedRows[0];
//    for(let i=0; i < selectedRows.length; i++){
//        console.log('# : '+selectedRows[i].Description)
//    }

}

onClick(event){

}

onSubmitHandle(event){
//    const selectEvent = new CustomEvent('selection', {
//        detail: this.selectedRow;
//    });
//    this.dispatchEvent(selectEvent);
}


}