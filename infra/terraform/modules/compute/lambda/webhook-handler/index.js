exports.handler = async (event) => {
  console.log("Webhook event:", JSON.stringify(event));

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: "Webhook received"
    })
  };
};