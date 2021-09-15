export default (req, res) => {
  console.log('[Error] some error occurred');
  res.status(200).json({ text: 'Hello' })
}
