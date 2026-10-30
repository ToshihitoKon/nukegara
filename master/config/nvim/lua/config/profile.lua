local M = {}

M.is_review = os.getenv('NVIM_PROFILE') == 'review'

return M
