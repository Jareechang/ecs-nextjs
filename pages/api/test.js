export default (req, res) => {
  //res.status(500).json({
    //text: 'error',
    //version: 5
  //});
  res.status(200).json({
    text: 'success',
    version: 4
  });
}
