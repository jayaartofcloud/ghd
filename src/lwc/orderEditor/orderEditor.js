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
	@track totalAmount = 0.00;
	@api firstName = 'John Doe';
	selectedRowData;
	totalOrderQty=[];
	selectedOrders =[]


	 draftFieldValues = [];

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
	 const updatedValues = this.template.querySelector("lightning-datatable").draftValues;
		console.log('#draftFieldValues:'+ JSON.stringify(updatedValues));
		var newRow;
		this.selectedRowData = this.data.map(row => {
			console.log('row:'+ JSON.stringify(row));
			const changes = updatedValues.find(changedElement => changedElement.Id  === row.Id);

			if(changes !== undefined || changes !== null){
			  newRow = Object.assign({}, row);
			}
			if(changes)
			{
				return Object.assign(newRow, changes)
			}
		});


		productService({jsonInput:JSON.stringify(this.selectedRowData),accountId:this.recordId}).then(result =>{
		if(result){
				this.showSuccessToast();
				this.template.querySelector("lightning-datatable").draftValues = [];

			}else if(error){
				console.log('error:'+error);
				this.showErrorToast(error);
			}
  		})
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

		parseToObjectCollection(arrayOfArrays) {
          // Create an empty object to store the parsed data
          const objectCollection = {};

          // Loop through each inner array
          arrayOfArrays.forEach(innerArray => {
            // Loop through each object in the inner array
            innerArray.forEach(obj => {
              // Loop through each key-value pair in the object
              Object.entries(obj).forEach(([key, value]) => {
                // If the key doesn't exist in the object collection yet, create a new array for it
                if (!objectCollection[key]) {
                  objectCollection[key] = [];
                }
                // Push the value into the array for the current key
                objectCollection[key].push(value);
              });
            });
          });

          // Return the object collection
          return objectCollection;
        }


	handleOnCellChange(event){

	   console.log('event.detail.value:'+ JSON.stringify(event.detail.draftValues));
	   let selectedOrderQty = event.detail.draftValues;
	   const result = JSON.parse(JSON.stringify(event.detail.draftValues));

	   if(result[0].OrderQty === null || result[0].OrderQty === undefined ) return;

	   if(this.totalOrderQty != null || this.totalOrderQty !== undefined){
	          const preQty = this.selectedOrders.find(item => item.Id === result.Id);
           	   if(preQty != null || preQty != undefined ){
           	      if(result.OrderQty < preQty.OrderQty){
           	          result[0].OrderQty = result[0].OrderQty - preQty[0].OrderQty;
           	          this.totalOrderQty.push(preQty);
                  		}
					}else{
						 this.totalOrderQty.push(preQty);
					}
				}
				let qty = result[0].OrderQty;
				let id = result[0].Id;
				const singleRow = this.data.find(obj => obj.Id === id);
				this.totalAmount =  singleRow.UnitPrice * qty;
				this.selectedOrders.push(result);
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