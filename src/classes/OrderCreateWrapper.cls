/**
 * Created by Jayakumar Mogenahall on 15/03/2023.
 */

public class OrderCreateWrapper {

    public Decimal totalInclVat;
    public Decimal totalExclVat;
    public Date estimatedDeliveryDate;
    public List<OrderLineModel> products;
    public String poReference;
    public String accountId;

    public static OrderCreateWrapper parse(String json){
        System.debug('PARSING');
        return (OrderCreateWrapper)System.JSON.deserialize(json, OrderCreateWrapper.class);
    }
}