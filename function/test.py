import boto3
import simplejson
import smoketest

from lambda_function import lambda_handler


class TestAPI(smoketest.TestCase):
    def test_putApi_works(self):

        result = lambda_handler(0,0)
        self.assertEqual(result['statusCode'], 200)

if __name__ == '__main__':
    smoketest.main()