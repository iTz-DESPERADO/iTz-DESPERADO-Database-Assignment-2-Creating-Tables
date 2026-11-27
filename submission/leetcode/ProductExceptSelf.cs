public class Solution
{

    //  Time : O(N + N) Space : O(1 + N (this is because we will make result array with same size of nums we can't avoid it here))
    //  become Time : O(N) and Space : O(N)   
    public int[] ProductExceptSelf(int[] nums)
    {

        int size = nums.Length;
        int[] result = new int[size];

        int prefix = 1;
        int suffix = 1;


        for (int i = 0; i < size; i++)
        {
            result[i] = prefix;
            prefix *= nums[i];
        }


        for (int i = size - 1; i >= 0; i--)
        {
            result[i] *= suffix;
            suffix *= nums[i];
        }

        return result;
    }

    /*   Time : O(N + N) Space : O(N + N + N)    become Time : O(N) and Space : O(N)
    public int[] ProductExceptSelf(int[] nums)
    {

        int size = nums.Length;
        int[] prefix = new int[size];
        int[] suffix = new int[size];

        prefix[0] = 1;
        suffix[size - 1] = 1;

        for (int i = 1; i < size; i++)
        {
            prefix[i] = nums[i - 1] * prefix[i - 1];
            int j = size - 1 - i;
            suffix[j] = nums[j + 1] * suffix[j + 1];
        }

        int[] result = new int[size];


        for (int i = 0; i < size; i++)
        {
            result[i] = prefix[i] * suffix[i];
        }


        return result;
    }
    */

}