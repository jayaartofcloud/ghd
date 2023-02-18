/**
 * Created by Jayakumar Mogenahall on 14/02/2023.
 */

import { LightningElement,wire,track,api} from 'lwc';
import generateData from './generateData';
import productsDump from '@salesforce/apex/ProductsDump.buildProductDump';
import productService from '@salesforce/apex/ProductService.create';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
// import {PROMOTION_MODEL} from 'c/promotion';


const columns = [
    { label: 'Product Name', fieldName: 'ProductName', editable: false},
    { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency', editable: true,cellAttributes:{iconName:{fieldName:'iconName'}, iconPosition:"right",'data-id':'curVal'} },
    { label: 'Order Qty', fieldName: 'OrderQty', type: 'number', editable: true },
    { label: 'Free Qty', fieldName: 'FreeQty', type: 'number', editable: true },
    { label: 'Promo Order Qty', fieldName: 'PromotionOrderQty', type: 'number',editable: true},
    { label: 'Promo Free Qty', fieldName: 'PromotionFreeQty', type: 'number',editable: true},
];

export default class orderEditor extends LightningElement {
   @api recordId;
   @track isShowModal = false;
    data = [];
    columns = columns;
    rowOffset = 0;
	selectedFamily = '--Select Family--';
	searchToken = '';
	family = '';
	wiredDataResult;
	@track totalAmount = 560.00;
	@api firstName = 'John Doe';

	//promotion
	name;


	get options() {
        return [
            {label:'All',value:'All'},
            {label: 'Styler', value:'Styler'},
            {label: 'ANZ - Prior Q Dryer', value:'ANZ - Prior Q Dryer'},
            {label: '12 Core Curl', value:'12 Core Curl'},
        ];
    }

	@wire(productsDump, {family:'$family',searchToken:'$searchToken'})
	wiredResult({error,data}){
	this.wiredDataResult = data;
		if(data){
			this.data = data.map(item=>{
				console.log('item:'+ JSON.stringify(item));
				let iconName = item.AvailableStock <= 5  ? "utility:down" : item.AvailableStock > 5 &&  item.AvailableStock <= 15 ? "utility:left": "utility:up";
				console.log('#iconName:'+iconName);
				return {...item, "iconName": iconName}
			});
				console.log(JSON.stringify(data));
			}
			else if(error){
				console.log('#Error:'+ JSON.stringify(error))
				alert(JSON.stringify(error));
			}
	}

	connectedCallback() {
		this.data = generateData({ amountOfRecords: 100 });
	}
	handleChange(event){
		this.selectedFamily = event.detail.value;
		this.makeProductDumpCall();
	}
	handleSearch(event){
		this.searchToken = event.target.value;
		this.makeProductDumpCall();
	}
    handleSave(event){
		var updatedRecords = this.template.querySelector("lightning-datatable").draftValues;
		var newRow;
		var rowsToSave = this.data.map(row => {
			console.log('row:'+ JSON.stringify(row));
			const changes = updatedRecords.find(changedElement => changedElement.Id  === row.Id);

			if(changes !== undefined || changes !== null){
			  newRow = Object.assign({}, row);
			}
			console.log('#newRow:' + newRow)
			console.log('#changes:' + changes)
			if(changes)
			{
				return Object.assign(newRow, changes)
			}
		});

		console.log('#rowsToSave:'+ JSON.stringify(rowsToSave));
		productService({jsonInput:JSON.stringify(rowsToSave),accountId:this.recordId}).then(result => {
			if(result){
				console.log('result:'+result);
				console.log('#this.wiredDataResult:'+this.wiredDataResult);
				this.showSuccessToast();
			}else if(error){
				 console.log('error:'+error);
				 this.showErrorToast(error);
			}
		return refreshApex(this.wiredDataResult);
		})

       // console.log('#selectedRows1:' + JSON.stringify(selectedRows1));
    }

	makeProductDumpCall(){
	productsDump({family:this.selectedFamily, searchToken : this.searchToken}).then(result => {
		this.data = result.map(item=>{
			let iconName = item.AvailableStock <= 5  ? "utility:down" : item.AvailableStock > 5 &&  item.AvailableStock <= 15 ? "utility:left": "utility:up";
			//  console.log('#iconName:'+iconName);
			return {...item, "iconName": iconName }
		});
		}).catch(error => {
		console.log('Error1:' + JSON.stringify(error));
		})
	}

	handleOnCellChange(event){
	   console.log('event.detail.value:'+ JSON.stringify(event.detail.draftValues));
	   console.log('event.target.dataset.id:'+event.target.dataset.id)
	}
	handleOnRowAction(event){

	}
    handleDraft(event){

    }

	showSuccessToast() {
		const event = new ShowToastEvent({
			title: 'Success!',
			message: 'Records Saved successfully',
			variant: 'success',
			mode: 'dismissable'
		});
		this.dispatchEvent(event);
	}

	showErrorToast(ex) {
		const evt = new ShowToastEvent({
			title: 'Error',
			message: ex,
			variant: 'error',
			mode: 'dismissable'
		});
		this.dispatchEvent(evt);
	}

// Promotion related functions
	showPromotionModel() {
		this.isShowModal = true;
	}

	hidePromotionModel() {
		this.isShowModal = false;
	}
	handlePromotionSubmit(){
		alert('Name is '+this.name);
		this.hidePromotionModel();
	}

	handleNameChange(event){
		this.name = event.detail.value;
	}
}