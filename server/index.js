const Express = require('express')
const cors = require('cors')
const bodyParser = require('body-parser')

const app = Express()
const port = '8888'

const database = {
  ghost: {}
}

app.use(cors())
app.use(bodyParser.json())

app.get('/', (req, res) => {
  res.send('hi')
})

app.post('/save', (req, res) => {
  const ghost = req.body
  console.log(`Saving ghost:
    x: ${ghost.x}
    y: ${ghost.y}
  `)
  database.ghost = ghost
  res.send('ok')
})

app.listen(port, () => {
  console.log(`Listening on port ${port}.`)
})
