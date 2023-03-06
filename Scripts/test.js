  const token = "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJvYXV0aDo0NTMiLCJleHAiOjE2Njg1NjM0NDgsImlhdCI6MTY2Nzk1ODY0OCwiaXNzIjoicGFyYWxsZWwiLCJqdGkiOiJkMjg2ZTdiYi1kNmQ0LTRhZGQtOTNhZS05ODJjNzRjOGQ5Y2UiLCJuYmYiOjE2Njc5NTg2NDcsInN1YiI6IjQ3MTYiLCJ0eXAiOiJKV1QifQ.5zN3QjgmSEtzaJBolYZZherMlJrH5mNrPNBTSaVXLUV4RmXi87bVenVK7Qc5aZEOL4YcmLc5czoKFUUKbYWIlQ"
  var config = {
    method: 'get',
    url: `https://api.parallelmarkets.com/v1/me`,
    headers: { "Authorization": `Bearer ${token}`  }

  };
 
  let dado;
  await axios(config).then(function (response) {
   dado = response
  })
  return(dado)
