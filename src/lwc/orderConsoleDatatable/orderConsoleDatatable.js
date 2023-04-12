/**
 * Created by Jayakumar Mogenahall on 07/03/2023.
 */

import { LightningDatatable } from 'lightning/datatable';
import unitPriceWithIConsTemplate from './unitPriceWithIConsTemplate.html';

export default class OrderConsoleDatatable extends LightningDatatable {
	static customTypes = {
	    unitPriceWithICons : unitPriceWithIConsTemplate,
	    standardCellLayout : true,
	    typeAttributes: ['a','b']
 	};
}