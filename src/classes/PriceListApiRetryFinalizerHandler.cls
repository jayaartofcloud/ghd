/**
 * Created by Jayakumar Mogenahall on 11/04/2023.
 */

public class PriceListApiRetryFinalizerHandler implements Finalizer{
    public void execute(FinalizerContext ctx) {
        String parentJobId = ctx.getAsyncApexJobId();
        if(ctx.getResult() == ParentJobResult.SUCCESS){
            //do nothing
            System.debug('### Parent queueable jobId =>' + parentJobId + ' completed successfully.');
        }else{
            System.debug('### Parent queueable job =>' + parentJobId + ' failed due to unhandled exception: ' + ctx.getException().getMessage());
            //enqueue failed job
            String newJobId = System.enqueueJob(new PriceListAPIProcessQueueable());
            System.debug('### Enqueued new jobId=> ' + newJobId);
        }
        System.debug('### Completed: execution of finalizer attached to queueable job => ' + parentJobId);
    }
}