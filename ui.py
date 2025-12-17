import streamlit as st
import get_response

st.set_page_config(page_title="PodSense", layout="centered")

if "input_data" not in st.session_state:
    st.session_state.input_data = None

st.markdown("<h1 style='text-align: center;'>PodSense</h1>", unsafe_allow_html=True)

option = st.selectbox("Select option to upload or URL", ("Upload", "URL"))

if option == "Upload":
    file = st.file_uploader("Choose an image", type=["png", "jpg", "jpeg"])
    if file is not None:
        st.session_state.input_data = file
else:
    url = st.text_input("Enter image URL")
    if url:
        st.session_state.input_data = url

if st.button("Predict"):
    if st.session_state.input_data:
        predictions = get_response.get_response(st.session_state.input_data)
        st.write(predictions)
        st.session_state.input_data = None

