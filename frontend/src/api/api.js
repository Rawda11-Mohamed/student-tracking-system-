import axios from 'axios'

const api = axios.create({
  baseURL: 'http://localhost:5001',
})

export const getStudents = () => api.get('/students')
export const getTopStudents = () => api.get('/top-students')
export const searchStudents = (name) => api.get(`/search?name=${name}`)
export const getStudentCourses = () => api.get('/student-courses')
export const getStudentsPerMajor = () => api.get('/students-per-major')
export const getGpaByYear = () => api.get('/gpa-by-year')
export const getAttendance = () => api.get('/attendance')
export const getCoursesByDept = (dept) => api.get(`/courses?department=${dept}`)
export const getCoursesRange = () => api.get('/courses-range')
export const updateGpa = (id, gpa) => api.post('/update-gpa', { id, gpa })
export const deleteEnrollment = (id) => api.post('/delete-enrollment', { id })

export default api
