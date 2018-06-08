const axios=require('axios')

axios.get('http://localhost:5000/nodedetails')
    .then(function (response) {
  

console.log(response.data)



let postdata=response.data.enode+1;



 axios.post('http://localhost:5000/noderesponse', {
            userid: postdata,
          })
          .then(function (response) {
          
          })
          .catch(function (error) {
            
          });
          






    })




