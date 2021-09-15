export default (req, res) => {
  res.status(500).json({
    text: 'error',
    version: 4
  });
  //res.status(200).json({
    //text: 'success',
    //version: 2
  //});
}
